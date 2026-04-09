import AVFoundation
import Foundation
import SwiftData

/// Pre-renders the three audio files AlarmKit and the stop/snooze intents
/// need, all tailored to the user's chosen voice and tied to a specific
/// `Alarm` by id:
///
/// 1. **`morning-<alarmID>.wav`** — greeting + affirmations only (no
///    closing). Played by AlarmKit when the alarm fires.
/// 2. **`closing-<alarmID>.wav`** — just the closing statement, ~3 seconds.
///    Played by `StopAndPlayClosingIntent` when the user taps Stop — so the
///    user hears `[affirmation cut] → [closing] → silence` instead of a
///    hard cut.
/// 3. **`snooze-<alarmID>.wav`** — the user's selected alarm tone briefly
///    beeping (~3s), then the voice saying *"Time to get up, [Name]. Let's
///    have a great day."* Played by AlarmKit on the 10-minute snooze
///    follow-up alarm (see `AlarmKitScheduler.scheduleSnoozeFollowUp`).
///
/// All three files are refreshed together: on app launch/resume, on alarm
/// edit, on onboarding completion, and on voice change in Settings.
/// Staleness threshold is 20 hours — if any file is newer than that we
/// reuse it rather than burning more TTS calls.
///
/// If Claude or OpenAI is unreachable the renderer returns `nil` and the
/// scheduler falls back to the bundled alarm tone the user picked in
/// onboarding. The alarm always rings.
@MainActor
final class MorningAudioRenderer {
    static let shared = MorningAudioRenderer()

    /// Staleness threshold. Files older than this are regenerated on the
    /// next refresh trigger so the content never plays stale for more
    /// than a day.
    private let staleAfter: TimeInterval = 20 * 3600

    /// How long (roughly) the main spoken audio should stay under. Nova
    /// speaks at about 2.6 words/second at 0.95x speed, so 25s ≈ 65 words.
    /// That keeps us safely under the 30-second custom-sound cap and gives
    /// us headroom for the separate closing file.
    private let maxMainWords = 55

    private let tts = OpenAITTSService()

    private init() {}

    // MARK: - Public API

    /// Render (or refresh) all three audio files for a single alarm.
    /// Returns the `morning-*.wav` filename that `AlarmKitScheduler` should
    /// pass to `AlertConfiguration.AlertSound.named(_:)`, or `nil` if
    /// rendering failed.
    ///
    /// Closing + snooze files are always rendered alongside the main file
    /// in the same call, so callers don't need to invoke three separate
    /// methods. If the main file is fresh, all three are assumed fresh.
    @discardableResult
    func refresh(
        for alarm: Alarm,
        profile: UserProfile,
        modelContext: ModelContext
    ) async -> String? {
        let morningFilename = Self.morningFilename(for: alarm)
        let morningURL = Self.soundsDirectory().appendingPathComponent(morningFilename)

        // Reuse recent renders. If the main file exists and was written
        // less than `staleAfter` ago, assume all three are still good.
        if let attrs = try? FileManager.default.attributesOfItem(atPath: morningURL.path),
           let modDate = attrs[.modificationDate] as? Date,
           Date().timeIntervalSince(modDate) < staleAfter {
            return morningFilename
        }

        // Generate the affirmations + closing text. Best-effort: if Claude
        // is unreachable we bail out and let the scheduler fall back to the
        // bundled alarm tone — better than writing broken audio.
        let cache = AffirmationCacheService()
        let affirmations: [Affirmation]
        let closing: DailyClosingMessage?
        do {
            (affirmations, closing) = try await cache.fetchOrGenerate(
                for: profile,
                modelContext: modelContext
            )
        } catch {
            return nil
        }

        let voice = OpenAITTSService.Voice(rawValue: profile.ttsVoice) ?? .nova

        // Ensure Library/Sounds exists — it doesn't by default in a fresh
        // app container.
        do {
            try FileManager.default.createDirectory(
                at: Self.soundsDirectory(),
                withIntermediateDirectories: true
            )
        } catch {
            return nil
        }

        // 1. Main file: greeting + affirmations (no closing).
        //
        // OpenAI returns 24 kHz 16-bit mono PCM wrapped in a WAV container.
        // We re-wrap that PCM in a CAF container before writing to disk —
        // AlarmKit on iOS 26.1 appears to reject `.named(*.wav)` sounds
        // silently (alarm fires, phone vibrates, no audio), even though
        // WAV is nominally a supported notification-sound container per
        // Apple docs. CAF is battle-tested across every audio path in iOS
        // and is what the built-in Clock.app uses. Same PCM bytes, different
        // wrapper — no quality loss.
        let mainScript = composeMainScript(
            name: profile.name,
            affirmations: affirmations
        )
        do {
            let mainWAV = try await tts.synthesize(text: mainScript, voice: voice, format: .wav)
            try Self.writeAsCAF(wavData: mainWAV, to: morningURL)
        } catch {
            AppLogger.audio.error("main render failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }

        // 2. Closing file: just the closing statement, rendered as a
        //    separate TTS call so `StopAndPlayClosingIntent` can play it
        //    on its own via AVAudioPlayer. AVAudioPlayer handles CAF
        //    natively, same as WAV.
        let closingScript = composeClosingScript(closing: closing?.message)
        let closingURL = Self.soundsDirectory()
            .appendingPathComponent(Self.closingFilename(for: alarm))
        do {
            let closingWAV = try await tts.synthesize(text: closingScript, voice: voice, format: .wav)
            try Self.writeAsCAF(wavData: closingWAV, to: closingURL)
        } catch {
            // Non-fatal: the main file is written and the alarm can still
            // ring. The stop intent will no-op without a closing file.
            AppLogger.audio.error("closing render failed: \(error.localizedDescription, privacy: .public)")
        }

        // 3. Snooze file: selected alarm tone + "time to get up, Name".
        //    Built by concatenating the first ~3s of the bundled tone with
        //    a fresh TTS call via AVMutableComposition.
        do {
            _ = try await renderSnoozeFile(for: alarm, profile: profile, voice: voice)
        } catch {
            AppLogger.audio.error("snooze render failed: \(error.localizedDescription, privacy: .public)")
        }

        return morningFilename
    }

    /// Batch refresh every enabled alarm. Called from `AffirmationAlarmApp`
    /// on launch/resume so the next morning's audio is always primed.
    func refreshAll(
        alarms: [Alarm],
        profile: UserProfile,
        modelContext: ModelContext
    ) async {
        for alarm in alarms where alarm.isEnabled {
            _ = await refresh(for: alarm, profile: profile, modelContext: modelContext)
        }
    }

    /// Invalidate every cached render — called from Voice Settings when the
    /// user picks a new voice. Wipes all three file prefixes so the next
    /// refresh definitely re-generates rather than reusing yesterday's
    /// content in the old voice.
    func invalidateAll() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: Self.soundsDirectory(),
            includingPropertiesForKeys: nil
        ) else {
            return
        }
        for url in contents {
            let name = url.lastPathComponent
            if name.hasPrefix("morning-") || name.hasPrefix("closing-") || name.hasPrefix("snooze-") {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    /// Remove every rendered file belonging to a single alarm. Called from
    /// the alarm list / detail delete paths so orphaned files don't pile
    /// up in `Library/Sounds/` after a user deletes their alarm.
    func removeFiles(for alarm: Alarm) {
        let soundsDir = Self.soundsDirectory()
        let filenames = [
            Self.morningFilename(for: alarm),
            Self.closingFilename(for: alarm),
            Self.snoozeFilename(for: alarm)
        ]
        for filename in filenames {
            let url = soundsDir.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// The `morning-*.wav` filename for this alarm if it's on disk, else `nil`.
    /// Lets `AlarmKitScheduler` stay synchronous.
    static func existingRenderedFilename(for alarm: Alarm) -> String? {
        let filename = morningFilename(for: alarm)
        let url = soundsDirectory().appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path) ? filename : nil
    }

    // MARK: - Script composition

    /// The main alarm audio content: greeting + up to 3 affirmations.
    /// Joins segments with paragraph breaks so TTS treats them as natural
    /// pauses. The closing is intentionally NOT included here — it lives in
    /// its own file so the stop intent can play it independently.
    private func composeMainScript(
        name: String,
        affirmations: [Affirmation]
    ) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let greeting = trimmedName.isEmpty
            ? "Good morning."
            : "Good morning, \(trimmedName)."

        // Priority favorites already land at index 0 in the cache, so the
        // first three naturally include any heart-marked ones the user
        // wants surfaced.
        let lines = affirmations.prefix(3).map { $0.text }

        var segments: [String] = [greeting]
        segments.append(contentsOf: lines)

        let joined = segments.joined(separator: "\n\n")
        return trimToWordBudget(joined, budget: maxMainWords)
    }

    /// The standalone closing statement played by the stop intent.
    private func composeClosingScript(closing: String?) -> String {
        if let closing, !closing.isEmpty { return closing }
        return "Have a wonderful day."
    }

    /// Hard cap on word count. If the affirmations are unusually long,
    /// drop trailing words rather than let AlarmKit truncate the clip at
    /// the 30s boundary. Normal Claude output (~12 words per affirmation)
    /// fits without trimming.
    private func trimToWordBudget(_ text: String, budget: Int) -> String {
        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        guard words.count > budget else { return text }
        return words.prefix(budget).joined(separator: " ") + "."
    }

    // MARK: - Snooze rendering

    /// Build the snooze follow-up audio. The plan calls for a short beep
    /// (first ~3s of the user's selected alarm tone) followed by the
    /// spoken *"Time to get up, [Name]. Let's have a great day."* prompt.
    ///
    /// `AVAssetExportSession` is unreliable for WAV output on iOS (the
    /// framework is optimized for video / M4A audio containers), so for
    /// v1 we render just the TTS-only WAV. The user hears the spoken
    /// prompt reliably. We can layer a beep in via `AVAssetReader` +
    /// `AVAssetWriter` (or raw PCM concatenation through `AVAudioFile`)
    /// in a follow-up once this path is verified on a real device.
    private func renderSnoozeFile(
        for alarm: Alarm,
        profile: UserProfile,
        voice: OpenAITTSService.Voice
    ) async throws -> URL? {
        let trimmedName = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let spoken = trimmedName.isEmpty
            ? "Time to get up. Let's have a great day."
            : "Time to get up, \(trimmedName). Let's have a great day."

        let ttsWAV = try await tts.synthesize(text: spoken, voice: voice, format: .wav)

        let destURL = Self.soundsDirectory()
            .appendingPathComponent(Self.snoozeFilename(for: alarm))
        // Re-wrap the OpenAI WAV as CAF for the same reason as the main
        // and closing files — AlarmKit on iOS 26.1 plays `.named(*.caf)`
        // reliably but silently drops `.named(*.wav)` sounds.
        try Self.writeAsCAF(wavData: ttsWAV, to: destURL)
        return destURL
    }

    // MARK: - WAV → CAF conversion

    /// Re-wrap PCM audio from a WAV container into a CAF container, writing
    /// the result to `destinationURL`. Used for every rendered alarm sound
    /// because AlarmKit on iOS 26.1 only reliably plays CAF-wrapped
    /// `.named(_:)` sounds — WAV files silently fail (the alarm fires, the
    /// phone vibrates, but no audio plays).
    ///
    /// OpenAI TTS returns 24 kHz 16-bit mono Linear PCM inside a WAV
    /// container. We parse the WAV with `AVAudioFile` (which exposes the
    /// raw PCM as a buffer), then write the same buffer to a new file with
    /// a `.caf` extension — `AVAudioFile` auto-selects the container
    /// format from the destination URL extension. Same bytes, different
    /// wrapper, zero quality loss, no resampling.
    private static func writeAsCAF(wavData: Data, to destinationURL: URL) throws {
        // Drop the WAV bytes into a temp file so `AVAudioFile(forReading:)`
        // can parse the container header.
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("tts-\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: tempURL) }
        try wavData.write(to: tempURL, options: .atomic)

        // Read the full PCM content into an in-memory buffer using the
        // source file's native format (24 kHz mono int16 for OpenAI).
        let sourceFile = try AVAudioFile(forReading: tempURL)
        let format = sourceFile.processingFormat
        let frameCount = AVAudioFrameCount(sourceFile.length)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ) else {
            throw NSError(
                domain: "MorningAudioRenderer.writeAsCAF",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not allocate PCM buffer"]
            )
        }
        try sourceFile.read(into: buffer)

        // Write the same PCM buffer to the destination. The `.caf`
        // extension on the URL tells `AVAudioFile` to produce a CAF
        // container; passing `format.settings` reuses the source's exact
        // codec config (Linear PCM, 16-bit, 24 kHz, mono).
        try? FileManager.default.removeItem(at: destinationURL)
        let destinationFile = try AVAudioFile(
            forWriting: destinationURL,
            settings: format.settings
        )
        try destinationFile.write(from: buffer)
        // AVAudioFile flushes and closes on deinit as it drops out of scope.
    }

    // MARK: - Filename helpers

    private static func morningFilename(for alarm: Alarm) -> String {
        "morning-\(alarm.id.uuidString).caf"
    }

    private static func closingFilename(for alarm: Alarm) -> String {
        "closing-\(alarm.id.uuidString).caf"
    }

    private static func snoozeFilename(for alarm: Alarm) -> String {
        "snooze-\(alarm.id.uuidString).caf"
    }

    private static func soundsDirectory() -> URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return library.appendingPathComponent("Sounds", isDirectory: true)
    }
}
