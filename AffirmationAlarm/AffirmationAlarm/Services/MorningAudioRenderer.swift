import AVFoundation
import Foundation
import SwiftData

/// Renders per-alarm personalized Nova-voice audio to `Library/Sounds/`.
///
/// ## Output files (per Alarm ID)
///
/// | Filename                    | Purpose                                     | Played by                  |
/// |-----------------------------|---------------------------------------------|----------------------------|
/// | `morning-<id>.mp3`          | greeting + N affirmations                   | `AlarmAudioPlayer` when    |
/// |                             |                                             | the observer catches the   |
/// |                             |                                             | alarm firing, or when the  |
/// |                             |                                             | user slides Stop.          |
/// | `closing-<id>.mp3`          | closing statement, ~2-3 seconds             | `AlarmAudioPlayer` right   |
/// |                             |                                             | after the morning MP3.     |
///
/// ## Why we don't render the alarm sound itself
///
/// `AlertConfiguration.AlertSound.named()` only reliably reads audio from
/// the **app bundle** on iOS 26.3.1 — FB19779004 (unresolved as of Apr
/// 2026) makes `Library/Sounds/` audio silently fall back to `.default`.
/// The scheduler passes `.named(alarm.soundName)` pointing to a bundled
/// CAF like `alarm_gentle.caf` (a brief tone, ~1s). The personalized
/// Nova-voice audio is layered on top by `AlarmAudioPlayer` the moment
/// the `alarmUpdates` observer catches the fire event.
///
/// ## When rendering runs
///
/// - App launch / resume (`refreshAll`)
/// - Alarm create / edit (`refresh(for:profile:modelContext:)`)
/// - Onboarding complete (`refresh`)
/// - Voice change in Settings (`invalidateAll` then `refreshAll`)
///
/// Renders are reused if the morning MP3 is less than `staleAfter` old,
/// so repeated calls during the same day don't burn TTS credits.
@MainActor
final class MorningAudioRenderer {

    // MARK: - Singleton

    static let shared = MorningAudioRenderer()

    private init() {}

    // MARK: - Configuration

    /// Renders older than this are considered stale and will be regenerated
    /// on the next refresh call. 6h means an evening render always
    /// refreshes by morning, and a just-fired alarm's reconcile pass
    /// always produces a fresh render for tomorrow.
    private let staleAfter: TimeInterval = 300

    private let tts = ElevenLabsTTSService()

    // MARK: - Public API

    /// Render (or refresh) the morning + closing MP3 for a single alarm.
    /// Returns the morning MP3 filename on success, or `nil` if content
    /// generation or the morning render failed.
    ///
    /// If the morning MP3 already exists and is less than `staleAfter`
    /// old, returns its filename without re-rendering — the closing MP3
    /// is assumed fresh too since the two files are always written
    /// together.
    @discardableResult
    func refresh(
        for alarm: Alarm,
        profile: UserProfile,
        modelContext: ModelContext,
        exclude: [String] = []
    ) async -> (filename: String?, usedTexts: [String]) {
        let paths = RenderPaths(alarmID: alarm.id)

        if isFresh(paths.morning) { return (paths.morning.lastPathComponent, []) }

        guard ensureSoundsDirectoryExists() else { return (nil, []) }

        let content: RenderContent
        do {
            content = try await buildContent(for: alarm, profile: profile, modelContext: modelContext, exclude: exclude)
        } catch {
            AppLogger.audio.error("content build failed: \(error.localizedDescription, privacy: .public)")
            return (nil, [])
        }

        // The morning MP3 is required — if it fails there's nothing to
        // play. The closing MP3 is best-effort: a transient TTS failure
        // on it shouldn't block the whole render.
        guard await renderMainMP3(to: paths.morning, script: content.mainScript, voice: content.voice) else {
            return (nil, [])
        }
        await renderClosing(
            to: paths.closing,
            script: content.closingScript,
            voice: content.voice,
            alarmID: alarm.id
        )

        return (paths.morning.lastPathComponent, content.affirmationTexts)
    }

    /// Render every enabled alarm. Called on app launch so tomorrow's
    /// audio is primed before the user wakes up.
    func refreshAll(
        alarms: [Alarm],
        profile: UserProfile,
        modelContext: ModelContext
    ) async {
        var exclude: [String] = []
        for alarm in alarms where alarm.isEnabled {
            let (_, usedTexts) = await refresh(
                for: alarm,
                profile: profile,
                modelContext: modelContext,
                exclude: exclude
            )
            exclude.append(contentsOf: usedTexts)
        }
    }

    /// Render morning + closing MP3s for a snooze follow-up UUID that has
    /// no corresponding `Alarm` SwiftData object. Called from
    /// `RootView.reconcileAlarmsWithSystem` which drains
    /// `AlarmKitScheduler.pendingFollowUpRenders` during the 10-minute
    /// snooze window.
    func renderForFollowUp(
        followUpID: UUID,
        profile: UserProfile,
        modelContext: ModelContext
    ) async {
        let paths = RenderPaths(alarmID: followUpID)

        guard ensureSoundsDirectoryExists() else { return }

        let cache = AffirmationCacheService()
        let voice = ElevenLabsTTSService.Voice(rawValue: profile.ttsVoice) ?? .rachel
        let count = profile.affirmationCount

        do {
            let (affirmations, closing) = try await cache.fetchOrGenerate(
                for: profile,
                modelContext: modelContext
            )

            let composer = ScriptComposer(
                name: profile.name,
                affirmations: affirmations,
                affirmationCount: count,
                closingMessage: closing?.message
            )

            guard await renderMainMP3(to: paths.morning, script: composer.main(), voice: voice) else {
                return
            }
            await renderClosing(
                to: paths.closing,
                script: composer.closing(),
                voice: voice,
                alarmID: followUpID
            )

            DiagnosticsLog.shared.log("render", "follow-up \(followUpID.uuidString.prefix(8)) rendered")
        } catch {
            AppLogger.audio.error("follow-up render failed: \(error.localizedDescription, privacy: .public)")
            DiagnosticsLog.shared.log("render", "follow-up render failed: \(error.localizedDescription)")
        }
    }

    /// Mark every rendered file as stale so the next `refresh()` call
    /// regenerates. Files stay on disk as a fallback — if re-rendering
    /// fails (API timeout, no network), the alarm still has audio to play
    /// instead of falling through to the system tone.
    func invalidateAll() {
        let dir = Self.soundsDirectory()
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        ) else { return }

        let epoch = Date(timeIntervalSince1970: 0)
        for url in contents where url.lastPathComponent.hasAnyPrefix(RenderPaths.allPrefixes) {
            try? FileManager.default.setAttributes(
                [.modificationDate: epoch],
                ofItemAtPath: url.path
            )
        }
    }

    /// Remove every file for a specific alarm. Called from alarm delete.
    func removeFiles(for alarm: Alarm) {
        removeFiles(alarmID: alarm.id)
    }

    /// UUID variant for callers that don't hold the `Alarm` object —
    /// notably `AlarmKitScheduler.handleFire`, which invalidates the MP3
    /// right after playback so the next render generates a fresh set of
    /// affirmations for tomorrow (or for the next fire on a repeating
    /// alarm later today).
    func removeFiles(alarmID: UUID) {
        let paths = RenderPaths(alarmID: alarmID)
        for url in paths.all {
            try? FileManager.default.removeItem(at: url)
        }
        DiagnosticsLog.shared.log("render", "removed files for \(alarmID.uuidString.prefix(8))")
    }

    // MARK: - Public paths

    /// `~/Library/Sounds` — where the rendered MP3s live on disk.
    /// `AlarmAudioPlayer` reads from here via
    /// `FileManager.default.urls(for: .libraryDirectory, …)`.
    nonisolated static func soundsDirectory() -> URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return library.appendingPathComponent("Sounds", isDirectory: true)
    }

    // MARK: - Content building

    private struct RenderContent {
        let mainScript: String
        let closingScript: String
        let voice: ElevenLabsTTSService.Voice
        let affirmationTexts: [String]
    }

    private func buildContent(
        for alarm: Alarm,
        profile: UserProfile,
        modelContext: ModelContext,
        exclude: [String] = []
    ) async throws -> RenderContent {
        let cache = AffirmationCacheService()
        let (affirmations, closing) = try await cache.fetchOrGenerate(
            for: profile,
            modelContext: modelContext,
            exclude: exclude
        )

        let voice = ElevenLabsTTSService.Voice(rawValue: profile.ttsVoice) ?? .rachel
        let count = profile.affirmationCount

        let composer = ScriptComposer(
            name: profile.name,
            affirmations: affirmations,
            affirmationCount: count,
            closingMessage: closing?.message
        )

        return RenderContent(
            mainScript: composer.main(),
            closingScript: composer.closing(),
            voice: voice,
            affirmationTexts: affirmations.map(\.text)
        )
    }

    // MARK: - Rendering primitives

    private func renderMainMP3(to url: URL, script: String, voice: ElevenLabsTTSService.Voice) async -> Bool {
        do {
            let ttsData = try await tts.synthesize(text: script, voice: voice)
            let data = await prependBirdsIntro(to: ttsData) ?? ttsData
            try data.write(to: url, options: .atomic)
            guard verifyPlayable(at: url, label: "main MP3") else { return false }
            DiagnosticsLog.shared.log("render", "main MP3 rendered \(url.lastPathComponent) size=\(data.count)")
            return true
        } catch {
            AppLogger.audio.error("main MP3 render failed: \(error.localizedDescription, privacy: .public)")
            DiagnosticsLog.shared.log("render", "main MP3 failed: \(error.localizedDescription)")
            return false
        }
    }

    private static let birdsIntroDuration: Double = 3.0

    private func prependBirdsIntro(to ttsData: Data) async -> Data? {
        guard let birdsURL = Bundle.main.url(forResource: "alarm_birds", withExtension: "caf") else {
            DiagnosticsLog.shared.log("render", "alarm_birds.caf not found in bundle — skipping intro")
            return nil
        }

        let tempTTS = Self.soundsDirectory().appendingPathComponent("tmp_tts.mp3")
        let tempOut = Self.soundsDirectory().appendingPathComponent("tmp_combined.m4a")
        defer {
            try? FileManager.default.removeItem(at: tempTTS)
            try? FileManager.default.removeItem(at: tempOut)
        }

        do {
            try ttsData.write(to: tempTTS, options: .atomic)

            let birdsAsset = AVAsset(url: birdsURL)
            let ttsAsset = AVAsset(url: tempTTS)
            let composition = AVMutableComposition()

            guard let birdsTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else { return nil }

            let birdsDuration = CMTime(seconds: Self.birdsIntroDuration, preferredTimescale: 44100)
            if let srcTrack = birdsAsset.tracks(withMediaType: .audio).first {
                let available = min(birdsDuration, srcTrack.timeRange.duration)
                try birdsTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: available),
                    of: srcTrack,
                    at: .zero
                )
            }

            guard let ttsTrackSlot = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else { return nil }

            if let srcTrack = ttsAsset.tracks(withMediaType: .audio).first {
                try ttsTrackSlot.insertTimeRange(
                    CMTimeRange(start: .zero, duration: srcTrack.timeRange.duration),
                    of: srcTrack,
                    at: birdsTrack.timeRange.duration
                )
            }

            guard let exportSession = AVAssetExportSession(
                asset: composition,
                presetName: AVAssetExportPresetAppleM4A
            ) else { return nil }

            exportSession.outputURL = tempOut
            exportSession.outputFileType = .m4a
            await exportSession.export()

            guard exportSession.status == .completed else {
                DiagnosticsLog.shared.log("render", "birds intro export failed: \(exportSession.error?.localizedDescription ?? "unknown")")
                return nil
            }

            return try Data(contentsOf: tempOut)
        } catch {
            DiagnosticsLog.shared.log("render", "birds intro prepend failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Render the closing MP3, short-circuiting to a bundled
    /// `closing-default.mp3` when the script is a canonical default line
    /// we pre-rendered at build time. Saves a TTS round-trip for the
    /// majority of users who haven't diverged from the default.
    ///
    /// If the bundled asset is missing OR the script is user-personal,
    /// falls through to the normal TTS render.
    private func renderClosing(
        to url: URL,
        script: String,
        voice: ElevenLabsTTSService.Voice,
        alarmID: UUID
    ) async {
        if copyBundledClosingIfEligible(to: url, script: script) {
            AlarmTelemetry.event(.closingTTSSkipped, alarmID: alarmID)
            DiagnosticsLog.shared.log("render", "closing skipped TTS — used bundled default")
            return
        }
        await renderSupportingMP3(to: url, script: script, voice: voice, label: "closing")
    }

    /// Returns true if `script` matches a canonical bundled closing AND the
    /// pre-rendered MP3 is present in the app bundle, in which case the
    /// file is copied to `url`. A missing bundle resource is not an error
    /// — we just fall back to TTS.
    private func copyBundledClosingIfEligible(to url: URL, script: String) -> Bool {
        let trimmed = script.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.defaultClosings.contains(trimmed) else { return false }
        guard let bundled = Bundle.main.url(forResource: "closing-default", withExtension: "mp3") else {
            return false
        }
        do {
            try? FileManager.default.removeItem(at: url)
            try FileManager.default.copyItem(at: bundled, to: url)
            return verifyPlayable(at: url, label: "closing (bundled)")
        } catch {
            AppLogger.audio.error("bundled closing copy failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// Canonical closing strings for which a pre-rendered MP3 is shipped
    /// in the bundle. Must stay in sync with `BundledAffirmationPool.closings`
    /// and the `ScriptComposer.closing()` fallback ("Have a wonderful day.").
    private static let defaultClosings: Set<String> = Set(
        BundledAffirmationPool.closings + ["Now go — the day is lucky to have you in it."]
    )

    private func renderSupportingMP3(
        to url: URL,
        script: String,
        voice: ElevenLabsTTSService.Voice,
        label: String
    ) async {
        do {
            let data = try await tts.synthesize(text: script, voice: voice)
            try data.write(to: url, options: .atomic)
            if verifyPlayable(at: url, label: "\(label) MP3") {
                DiagnosticsLog.shared.log("render", "\(label) MP3 rendered \(url.lastPathComponent) size=\(data.count)")
            }
        } catch {
            AppLogger.audio.error("\(label, privacy: .public) MP3 render failed: \(error.localizedDescription, privacy: .public)")
            DiagnosticsLog.shared.log("render", "\(label) MP3 failed: \(error.localizedDescription)")
        }
    }

    /// After a file is written to disk, confirm `AVAudioPlayer` can open
    /// it. Catches silent failures where the bytes exist but the
    /// container/encoding is malformed — unlikely with OpenAI's MP3
    /// responses, but cheap insurance against a silent render-but-don't-
    /// play failure mode.
    ///
    /// On failure, deletes the file so the next `refresh` attempts a
    /// fresh render instead of considering the alarm "fresh" via the
    /// `isFresh` short-circuit.
    @discardableResult
    private func verifyPlayable(at url: URL, label: String) -> Bool {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            if player.duration <= 0 {
                AppLogger.audio.error("\(label, privacy: .public) verify: zero-duration file at \(url.lastPathComponent, privacy: .public)")
                DiagnosticsLog.shared.log("render", "\(label) zero-duration — deleting")
                try? FileManager.default.removeItem(at: url)
                return false
            }
            AppLogger.audio.info("\(label, privacy: .public) verify: duration=\(player.duration, privacy: .public)s")
            return true
        } catch {
            AppLogger.audio.error("\(label, privacy: .public) verify failed: \(error.localizedDescription, privacy: .public)")
            DiagnosticsLog.shared.log("render", "\(label) verify failed: \(error.localizedDescription) — deleting")
            try? FileManager.default.removeItem(at: url)
            return false
        }
    }

    // MARK: - Disk helpers

    private func isFresh(_ url: URL) -> Bool {
        guard
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
            let modified = attrs[.modificationDate] as? Date
        else { return false }
        return Date().timeIntervalSince(modified) < staleAfter
    }

    private func ensureSoundsDirectoryExists() -> Bool {
        do {
            try FileManager.default.createDirectory(
                at: Self.soundsDirectory(),
                withIntermediateDirectories: true
            )
            return true
        } catch {
            AppLogger.audio.error("could not create Sounds dir: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}

// MARK: - Script composition

/// Builds the text scripts spoken by TTS. Pure logic — no I/O, no TTS
/// calls — so it's easy to reason about and change independently from
/// the rendering pipeline.
private struct ScriptComposer {
    let name: String
    let affirmations: [Affirmation]
    let affirmationCount: Int
    let closingMessage: String?

    /// Morning MP3: greeting + exactly `affirmationCount` affirmations.
    /// The user's selected count is the source of truth — Claude's prompt
    /// already caps per-affirmation length via `claudeMaxTokens`, so we
    /// don't second-guess by truncating the joined script.
    func main() -> String {
        var segments = [greeting()]
        segments.append(contentsOf: affirmationLines())
        return segments.joined(separator: "\n\n")
    }

    /// Closing MP3: just the closing message (user-personal or fallback).
    /// Plays immediately after the morning MP3.
    func closing() -> String {
        if let text = closingMessage?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            return text
        }
        return "Now go — the day is lucky to have you in it."
    }

    // MARK: - Primitives

    private func greeting() -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Good morning." : "Good morning, \(trimmed)."
    }

    private func affirmationLines() -> [String] {
        // Priority favorites already sit at index 0 in the cache, so
        // `prefix(N)` naturally includes any heart-marked ones.
        affirmations.prefix(affirmationCount).map(\.text)
    }
}

// MARK: - Path convention

/// Encapsulates the filename convention for a single alarm's renders.
/// Keeps the stem strings in one place so they can't drift between the
/// renderer, player, and Diagnostics view.
private struct RenderPaths {
    let alarmID: UUID

    var morning: URL { path("morning-\(alarmID.uuidString).mp3") }
    var closing: URL { path("closing-\(alarmID.uuidString).mp3") }

    var all: [URL] { [morning, closing] }

    static let allPrefixes = ["morning-", "closing-"]

    private func path(_ name: String) -> URL {
        MorningAudioRenderer.soundsDirectory().appendingPathComponent(name)
    }
}

private extension String {
    func hasAnyPrefix(_ prefixes: [String]) -> Bool {
        prefixes.contains(where: self.hasPrefix)
    }
}
