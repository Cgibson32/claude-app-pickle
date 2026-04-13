import AVFoundation
import Foundation
import SwiftData

/// Pre-renders personalized audio for each alarm.
///
/// **Primary path (iOS 26.3+, if FB19779004 is fixed):**
/// - **`alarm-<alarmID>.caf`** — greeting + affirmations + closing as one
///   CAF file. Passed to AlarmKit via `.named("alarm-<alarmID>")` so
///   mobiletimerd plays it as the alarm sound itself. User wakes to
///   personalized affirmations with no interaction.
///
///   CAF format is required because mobiletimerd historically only
///   supported WAV/AIFF/CAF for `.named()`. Filename passes WITHOUT
///   extension per AlarmKit convention.
///
/// **Fallback path (all iOS 26 versions, if .named() silently falls back):**
/// - **`morning-<alarmID>.mp3`** — greeting + affirmations (no closing).
/// - **`closing-<alarmID>.mp3`** — just the closing statement.
/// - **`snooze-<alarmID>.mp3`** — "Time to get up, [Name]."
///
/// These MP3s are played by `AlarmAudioPlayer` via `AVAudioPlayer` when
/// the user slides Stop (triggering `StopAndPlayClosingIntent`) or when
/// the `alarmUpdates` observer catches `.alerting` in foreground (Sleep
/// Mode). So even if the runtime CAF path doesn't fire, the user still
/// hears their affirmations the moment they interact.
///
/// All files refresh together: on app launch/resume, on alarm edit,
/// on onboarding completion, and on voice change in Settings. Staleness
/// threshold is 20 hours.
@MainActor
final class MorningAudioRenderer {
    static let shared = MorningAudioRenderer()

    /// Staleness threshold. Files older than this are regenerated on the
    /// next refresh trigger so the content never plays stale for more
    /// than a day.
    private let staleAfter: TimeInterval = 20 * 3600

    /// Word budget for the main script as a function of affirmation count.
    /// Nova speaks at about 2.6 words/sec at 0.95x speed (~2.47 wps).
    /// Since we play via AVAudioPlayer (not AlarmKit .named()), there's no
    /// 30-second cap. We cap at 80 words (~32s) for user comfort.
    private func wordBudget(for affirmationCount: Int) -> Int {
        let greetingWords = 3
        let wordsPerAffirmation = 15
        return min(greetingWords + wordsPerAffirmation * affirmationCount + 5, 80)
    }

    private let tts = OpenAITTSService()

    private init() {}

    // MARK: - Public API

    /// Render (or refresh) all three MP3 files for a single alarm.
    /// Returns the `morning-*.mp3` filename on success, or `nil` if
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
        //    MP3 from OpenAI TTS, played by AlarmAudioPlayer via AVAudioPlayer.
        let mainScript = composeMainScript(
            name: profile.name,
            affirmations: affirmations,
            affirmationCount: profile.affirmationCount
        )
        do {
            let mainMP3 = try await tts.synthesize(text: mainScript, voice: voice, format: .mp3)
            try mainMP3.write(to: morningURL, options: .atomic)
        } catch {
            AppLogger.audio.error("main render failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }

        // 2. Closing file: just the closing statement. AVAudioPlayer
        //    handles MP3 natively.
        let closingScript = composeClosingScript(closing: closing?.message)
        let closingURL = Self.soundsDirectory()
            .appendingPathComponent(Self.closingFilename(for: alarm))
        do {
            let closingMP3 = try await tts.synthesize(text: closingScript, voice: voice, format: .mp3)
            try closingMP3.write(to: closingURL, options: .atomic)
        } catch {
            AppLogger.audio.error("closing render failed: \(error.localizedDescription, privacy: .public)")
        }

        // 3. Snooze file: "Time to get up, Name. Let's have a great day."
        do {
            _ = try await renderSnoozeFile(for: alarm, profile: profile, voice: voice)
        } catch {
            AppLogger.audio.error("snooze render failed: \(error.localizedDescription, privacy: .public)")
        }

        // 4. Combined alarm CAF: greeting + affirmations + closing as one
        //    file for AlarmKit `.named()`. Primary playback path on iOS
        //    26.3+ if FB19779004 is fixed. Render succeeds either way;
        //    the scheduler decides whether to trust `.named()`.
        let fullScript = composeFullAlarmScript(
            name: profile.name,
            affirmations: affirmations,
            affirmationCount: profile.affirmationCount,
            closing: closing?.message
        )
        let alarmCAFURL = Self.soundsDirectory()
            .appendingPathComponent(Self.alarmCAFFilename(for: alarm))
        do {
            let wavData = try await tts.synthesize(text: fullScript, voice: voice, format: .wav)
            try Self.writeAsCAF(wavData: wavData, to: alarmCAFURL)
            AppLogger.audio.info("rendered alarm CAF for \(alarm.id.uuidString.prefix(8), privacy: .public)")
        } catch {
            AppLogger.audio.error("alarm CAF render failed: \(error.localizedDescription, privacy: .public)")
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
            if name.hasPrefix("alarm-") || name.hasPrefix("morning-") || name.hasPrefix("closing-") || name.hasPrefix("snooze-") {
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
            Self.alarmCAFFilename(for: alarm),
            Self.morningFilename(for: alarm),
            Self.closingFilename(for: alarm),
            Self.snoozeFilename(for: alarm)
        ]
        for filename in filenames {
            let url = soundsDir.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Script composition

    /// The main alarm audio content: greeting + the user's chosen number
    /// of affirmations. Joins segments with paragraph breaks so TTS
    /// treats them as natural pauses. The closing is intentionally NOT
    /// included here — it lives in its own file.
    private func composeMainScript(
        name: String,
        affirmations: [Affirmation],
        affirmationCount: Int
    ) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let greeting = trimmedName.isEmpty
            ? "Good morning."
            : "Good morning, \(trimmedName)."

        // Priority favorites already land at index 0 in the cache, so the
        // first N naturally include any heart-marked ones the user wants.
        let lines = affirmations.prefix(affirmationCount).map { $0.text }

        var segments: [String] = [greeting]
        segments.append(contentsOf: lines)

        let joined = segments.joined(separator: "\n\n")
        return trimToWordBudget(joined, budget: wordBudget(for: affirmationCount))
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

    /// Compose the full alarm sound script: greeting + affirmations + closing.
    /// This becomes a single CAF file that AlarmKit plays as the alarm sound.
    private func composeFullAlarmScript(
        name: String,
        affirmations: [Affirmation],
        affirmationCount: Int,
        closing: String?
    ) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let greeting = trimmedName.isEmpty
            ? "Good morning."
            : "Good morning, \(trimmedName)."

        let lines = affirmations.prefix(affirmationCount).map { $0.text }
        let closingLine = composeClosingScript(closing: closing)

        var segments: [String] = [greeting]
        segments.append(contentsOf: lines)
        segments.append(closingLine)

        let joined = segments.joined(separator: "\n\n")
        return trimToWordBudget(joined, budget: wordBudget(for: affirmationCount))
    }

    // MARK: - Snooze rendering

    /// Build the snooze follow-up audio: a TTS-only MP3 of
    /// *"Time to get up, [Name]. Let's have a great day."*
    private func renderSnoozeFile(
        for alarm: Alarm,
        profile: UserProfile,
        voice: OpenAITTSService.Voice
    ) async throws -> URL? {
        let trimmedName = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let spoken = trimmedName.isEmpty
            ? "Time to get up. Let's have a great day."
            : "Time to get up, \(trimmedName). Let's have a great day."

        let ttsMP3 = try await tts.synthesize(text: spoken, voice: voice, format: .mp3)

        let destURL = Self.soundsDirectory()
            .appendingPathComponent(Self.snoozeFilename(for: alarm))
        try ttsMP3.write(to: destURL, options: .atomic)
        return destURL
    }

    // MARK: - WAV → CAF conversion

    /// Re-wrap PCM audio from a WAV container into a CAF container.
    /// mobiletimerd (the system daemon that plays AlarmKit sounds) only
    /// supports WAV/AIFF/CAF for `.named()` — MP3 fails silently.
    /// We request WAV from OpenAI TTS (24 kHz 16-bit mono) and rewrap
    /// the raw PCM into a CAF container via AVAudioFile. Same bytes,
    /// different wrapper, zero quality loss.
    private static func writeAsCAF(wavData: Data, to destinationURL: URL) throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("tts-\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: tempURL) }
        try wavData.write(to: tempURL, options: .atomic)

        let sourceFile = try AVAudioFile(forReading: tempURL)
        let format = sourceFile.processingFormat
        let frameCount = AVAudioFrameCount(sourceFile.length)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ) else {
            throw NSError(
                domain: "MorningAudioRenderer",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not allocate PCM buffer"]
            )
        }
        try sourceFile.read(into: buffer)

        try? FileManager.default.removeItem(at: destinationURL)
        let destinationFile = try AVAudioFile(
            forWriting: destinationURL,
            settings: format.settings
        )
        try destinationFile.write(from: buffer)
    }

    // MARK: - Filename helpers

    /// The combined alarm sound filename (CAF) for AlarmKit `.named()`.
    static func alarmCAFFilename(for alarm: Alarm) -> String {
        "alarm-\(alarm.id.uuidString).caf"
    }

    /// The stem (no extension) passed to `.named()`. AlarmKit expects
    /// the filename without extension per convention.
    static func alarmCAFStem(for alarm: Alarm) -> String {
        "alarm-\(alarm.id.uuidString)"
    }

    /// Whether the combined CAF alarm sound exists on disk.
    static func hasAlarmCAF(for alarm: Alarm) -> Bool {
        let url = soundsDirectory().appendingPathComponent(alarmCAFFilename(for: alarm))
        return FileManager.default.fileExists(atPath: url.path)
    }

    private static func morningFilename(for alarm: Alarm) -> String {
        "morning-\(alarm.id.uuidString).mp3"
    }

    private static func closingFilename(for alarm: Alarm) -> String {
        "closing-\(alarm.id.uuidString).mp3"
    }

    private static func snoozeFilename(for alarm: Alarm) -> String {
        "snooze-\(alarm.id.uuidString).mp3"
    }

    nonisolated static func soundsDirectory() -> URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return library.appendingPathComponent("Sounds", isDirectory: true)
    }
}
