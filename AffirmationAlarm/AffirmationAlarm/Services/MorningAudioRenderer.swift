import AVFoundation
import Foundation
import SwiftData

/// Renders per-alarm personalized Nova-voice audio to `Library/Sounds/`.
///
/// ## Output files (per Alarm ID)
///
/// | Filename                    | Purpose                                     | Played by                  |
/// |-----------------------------|---------------------------------------------|----------------------------|
/// | `alarm-<id>.caf`            | greeting + affirmations + closing, single   | AlarmKit `.named()`        |
/// |                             | CAF — primary path if FB19779004 is fixed   | on iOS 26.3.1+             |
/// | `morning-<id>.mp3`          | greeting + affirmations (no closing)        | `AlarmAudioPlayer`         |
/// | `closing-<id>.mp3`          | closing statement only, ~3 seconds          | `AlarmAudioPlayer`         |
/// | `snooze-<id>.mp3`           | "Time to get up, [Name]. Let's have a        | Reserved for future        |
/// |                             | great day." — follow-up greeting            | snooze enhancement         |
///
/// ## When rendering runs
///
/// - App launch / resume (`refreshAll`)
/// - Alarm create / edit (`refresh(for:profile:modelContext:)`)
/// - Onboarding complete (`refresh`)
/// - Voice change in Settings (`invalidateAll` then `refreshAll`)
///
/// Renders are reused if the main MP3 is less than `staleAfter` old, so
/// repeated calls during the same day don't burn TTS credits.
///
/// ## Why CAF for the alarm sound
///
/// `AlertConfiguration.AlertSound.named()` historically only accepts
/// WAV/AIFF/CAF from `mobiletimerd`; MP3 fails silently. We request WAV
/// from OpenAI TTS (the server honors the format) and rewrap the PCM
/// samples into a CAF container via `AVAudioFile`. Same bytes, different
/// header — zero quality loss.
@MainActor
final class MorningAudioRenderer {

    // MARK: - Singleton

    static let shared = MorningAudioRenderer()

    private init() {}

    // MARK: - Configuration

    /// Renders older than this are considered stale and will be regenerated
    /// on the next refresh call. 20h means a daily refresh happens at most
    /// once, regardless of how many times the user opens the app.
    private let staleAfter: TimeInterval = 20 * 3600

    private let tts = OpenAITTSService()

    // MARK: - Public API

    /// Render (or refresh) all files for a single alarm. Returns the
    /// main `morning-*.mp3` filename on success, or `nil` if the content
    /// generation or main render failed.
    ///
    /// If the `morning-*.mp3` file already exists and is less than
    /// `staleAfter` old, returns its filename without re-rendering —
    /// the other three files are assumed fresh too since they're always
    /// rendered together.
    @discardableResult
    func refresh(
        for alarm: Alarm,
        profile: UserProfile,
        modelContext: ModelContext
    ) async -> String? {
        let paths = RenderPaths(alarmID: alarm.id)

        if isFresh(paths.morning) { return paths.morning.lastPathComponent }

        guard ensureSoundsDirectoryExists() else { return nil }

        let content: RenderContent
        do {
            content = try await buildContent(for: alarm, profile: profile, modelContext: modelContext)
        } catch {
            AppLogger.audio.error("content build failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }

        // The main morning MP3 is the only required file. The other three
        // are best-effort and logged individually so a transient TTS
        // failure on (say) the closing file doesn't block the whole render.
        guard await renderMainMP3(to: paths.morning, script: content.mainScript, voice: content.voice) else {
            return nil
        }
        await renderSupportingMP3(to: paths.closing, script: content.closingScript, voice: content.voice, label: "closing")
        await renderSupportingMP3(to: paths.snooze, script: content.snoozeScript, voice: content.voice, label: "snooze")
        await renderAlarmCAF(to: paths.alarmCAF, script: content.fullScript, voice: content.voice, alarmID: alarm.id)

        return paths.morning.lastPathComponent
    }

    /// Render every enabled alarm. Called on app launch so tomorrow's
    /// audio is primed before the user wakes up.
    func refreshAll(
        alarms: [Alarm],
        profile: UserProfile,
        modelContext: ModelContext
    ) async {
        for alarm in alarms where alarm.isEnabled {
            _ = await refresh(for: alarm, profile: profile, modelContext: modelContext)
        }
    }

    /// Wipe every rendered file (any alarm ID, any stem). Called when the
    /// user changes their TTS voice in Settings so the next refresh
    /// definitely regenerates rather than reusing yesterday's voice.
    func invalidateAll() {
        let dir = Self.soundsDirectory()
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        ) else { return }

        for url in contents where url.lastPathComponent.hasAnyPrefix(RenderPaths.allPrefixes) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Remove every file for a specific alarm. Called from alarm delete.
    func removeFiles(for alarm: Alarm) {
        let paths = RenderPaths(alarmID: alarm.id)
        for url in paths.all {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Static filename helpers (used by scheduler + player)

    /// The `alarm-<id>.caf` filename — what lives on disk.
    static func alarmCAFFilename(for alarm: Alarm) -> String {
        RenderPaths(alarmID: alarm.id).alarmCAF.lastPathComponent
    }

    /// The stem (no extension) passed to `AlertSound.named()`.
    /// AlarmKit convention is to drop the extension here.
    static func alarmCAFStem(for alarm: Alarm) -> String {
        "alarm-\(alarm.id.uuidString)"
    }

    /// Whether the combined alarm CAF has been rendered to disk.
    static func hasAlarmCAF(for alarm: Alarm) -> Bool {
        let url = RenderPaths(alarmID: alarm.id).alarmCAF
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// `~/Library/Sounds` — the only location AlarmKit documents as
    /// readable via `.named()` (see FB19779004 for caveats).
    nonisolated static func soundsDirectory() -> URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return library.appendingPathComponent("Sounds", isDirectory: true)
    }

    // MARK: - Content building

    private struct RenderContent {
        let mainScript: String
        let closingScript: String
        let snoozeScript: String
        let fullScript: String
        let voice: OpenAITTSService.Voice
    }

    private func buildContent(
        for alarm: Alarm,
        profile: UserProfile,
        modelContext: ModelContext
    ) async throws -> RenderContent {
        let cache = AffirmationCacheService()
        let (affirmations, closing) = try await cache.fetchOrGenerate(
            for: profile,
            modelContext: modelContext
        )

        let voice = OpenAITTSService.Voice(rawValue: profile.ttsVoice) ?? .nova
        let count = profile.affirmationCount
        let budget = wordBudget(for: count)

        let composer = ScriptComposer(
            name: profile.name,
            affirmations: affirmations,
            affirmationCount: count,
            closing: closing?.message,
            wordBudget: budget
        )

        return RenderContent(
            mainScript: composer.main(),
            closingScript: composer.closing(),
            snoozeScript: composer.snooze(),
            fullScript: composer.full(),
            voice: voice
        )
    }

    /// Nova at 0.95x speed runs about 2.47 wps. We play the morning MP3
    /// via `AVAudioPlayer` (no 30s cap from AlarmKit), so the budget here
    /// is for user comfort rather than a hard platform limit.
    private func wordBudget(for affirmationCount: Int) -> Int {
        let greeting = 3
        let perAffirmation = 15
        return min(greeting + perAffirmation * affirmationCount + 5, 80)
    }

    // MARK: - Rendering primitives

    private func renderMainMP3(to url: URL, script: String, voice: OpenAITTSService.Voice) async -> Bool {
        do {
            let data = try await tts.synthesize(text: script, voice: voice, format: .mp3)
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            AppLogger.audio.error("main MP3 render failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func renderSupportingMP3(
        to url: URL,
        script: String,
        voice: OpenAITTSService.Voice,
        label: String
    ) async {
        do {
            let data = try await tts.synthesize(text: script, voice: voice, format: .mp3)
            try data.write(to: url, options: .atomic)
        } catch {
            AppLogger.audio.error("\(label, privacy: .public) MP3 render failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func renderAlarmCAF(to url: URL, script: String, voice: OpenAITTSService.Voice, alarmID: UUID) async {
        do {
            let wav = try await tts.synthesize(text: script, voice: voice, format: .wav)
            try Self.rewrapWAVAsCAF(wav, to: url)
            AppLogger.audio.info("rendered alarm CAF for \(alarmID.uuidString.prefix(8), privacy: .public)")
        } catch {
            AppLogger.audio.error("alarm CAF render failed for \(alarmID.uuidString.prefix(8), privacy: .public): \(error.localizedDescription, privacy: .public)")
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

    // MARK: - WAV → CAF

    /// Re-wrap the PCM samples from a WAV container into a CAF container.
    /// mobiletimerd accepts WAV/AIFF/CAF for `.named()` but not MP3;
    /// CAF is the format Apple's own system sounds use.
    ///
    /// Uses `AVAudioFile` rather than raw bit manipulation so the CAF
    /// metadata (sample rate, channel count, bit depth) is always correct
    /// for whatever OpenAI TTS returns.
    private static func rewrapWAVAsCAF(_ wav: Data, to destination: URL) throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("tts-\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: temp) }
        try wav.write(to: temp, options: .atomic)

        let source = try AVAudioFile(forReading: temp)
        let format = source.processingFormat
        let frameCount = AVAudioFrameCount(source.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try source.read(into: buffer)

        try? FileManager.default.removeItem(at: destination)
        let output = try AVAudioFile(forWriting: destination, settings: format.settings)
        try output.write(from: buffer)
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
    let closing: String?
    let wordBudget: Int

    /// Morning MP3: greeting + N affirmations, no closing. Played by
    /// `AlarmAudioPlayer` when the alarm fires or the user slides Stop.
    func main() -> String {
        var segments = [greeting()]
        segments.append(contentsOf: affirmationLines())
        return trimmed(segments.joined(separator: "\n\n"))
    }

    /// Closing MP3: just the closing message (user-personal or fallback).
    func closing() -> String {
        if let text = closing?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            return text
        }
        return "Have a wonderful day."
    }

    /// Snooze MP3: named greeting. Reserved for future snooze
    /// enhancement — today the follow-up alarm uses `.default`.
    func snooze() -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
            ? "Time to get up. Let's have a great day."
            : "Time to get up, \(trimmed). Let's have a great day."
    }

    /// Full alarm CAF: greeting + affirmations + closing in one file.
    /// Passed to AlarmKit via `.named()` so the system daemon can play
    /// the personalized sequence as the alarm sound itself.
    func full() -> String {
        var segments = [greeting()]
        segments.append(contentsOf: affirmationLines())
        segments.append(closing())
        return trimmed(segments.joined(separator: "\n\n"))
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

    private func trimmed(_ text: String) -> String {
        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        guard words.count > wordBudget else { return text }
        return words.prefix(wordBudget).joined(separator: " ") + "."
    }
}

// MARK: - Path convention

/// Encapsulates the filename convention for a single alarm's renders.
/// Keeps the stem strings in one place so they can't drift between the
/// renderer, scheduler, and player.
private struct RenderPaths {
    let alarmID: UUID

    var alarmCAF: URL { path("alarm-\(alarmID.uuidString).caf") }
    var morning: URL { path("morning-\(alarmID.uuidString).mp3") }
    var closing: URL { path("closing-\(alarmID.uuidString).mp3") }
    var snooze: URL { path("snooze-\(alarmID.uuidString).mp3") }

    var all: [URL] { [alarmCAF, morning, closing, snooze] }

    static let allPrefixes = ["alarm-", "morning-", "closing-", "snooze-"]

    private func path(_ name: String) -> URL {
        MorningAudioRenderer.soundsDirectory().appendingPathComponent(name)
    }
}

private extension String {
    func hasAnyPrefix(_ prefixes: [String]) -> Bool {
        prefixes.contains(where: self.hasPrefix)
    }
}
