import Foundation
import SwiftData

/// Pre-renders the personalized morning ritual (greeting + 3 affirmations +
/// closing) as a single WAV file inside `Library/Sounds/` so AlarmKit can
/// play it as the alarm-fire sound. The user then literally wakes up to the
/// nurturing voice speaking their name and affirmations — not a generic
/// alarm tone.
///
/// Flow:
/// 1. Generate/fetch today's affirmations via `AffirmationCacheService`
///    (uses Claude, tailored to profile name/goals/categories/recent context)
/// 2. Compose the spoken script, trimmed so the audio stays under ~25s —
///    well inside the legacy 30s custom-sound cap that AlarmKit appears to
///    inherit from `UNNotificationSound`
/// 3. Request a WAV from OpenAI TTS at the user's chosen voice
/// 4. Write the bytes directly to `Library/Sounds/morning-<alarmID>.wav`
/// 5. `AlarmKitScheduler` picks the file up by filename via
///    `AlertConfiguration.AlertSound.named(_:)`
///
/// Rendered files are regenerated whenever the app becomes active, the
/// user edits the alarm, the user changes their voice in settings, or the
/// existing file is older than 20 hours — so the content stays fresh.
@MainActor
final class MorningAudioRenderer {
    static let shared = MorningAudioRenderer()

    /// Staleness threshold. Files older than this are regenerated on the
    /// next refresh trigger so the affirmations never play stale for more
    /// than a day.
    private let staleAfter: TimeInterval = 20 * 3600

    /// How long (roughly) the spoken audio should stay under. Nova speaks at
    /// about 2.6 words/second at 0.95x speed, so 25s ≈ 65 words. That's
    /// plenty for greeting + 3 affirmations + closing, and keeps us safely
    /// under the 30s custom-sound cap.
    private let maxWords = 65

    private let tts = OpenAITTSService()

    private init() {}

    // MARK: - Public API

    /// Render (or refresh) the morning audio for a single alarm. Returns the
    /// filename that `AlarmKitScheduler` should pass to
    /// `AlertConfiguration.AlertSound.named(_:)`, or `nil` if rendering
    /// failed — caller falls back to the bundled alarm tone.
    @discardableResult
    func refresh(
        for alarm: Alarm,
        profile: UserProfile,
        modelContext: ModelContext
    ) async -> String? {
        let filename = Self.filename(for: alarm)
        let fileURL = Self.soundsDirectory().appendingPathComponent(filename)

        // Reuse recent renders. If the file exists and was written less than
        // `staleAfter` ago, don't burn another TTS call.
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let modDate = attrs[.modificationDate] as? Date,
           Date().timeIntervalSince(modDate) < staleAfter {
            return filename
        }

        // Build the spoken script. Cache fetch is best-effort: if Claude is
        // unreachable we bail out and let the scheduler fall back to the
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

        let script = composeScript(
            name: profile.name,
            affirmations: affirmations,
            closing: closing?.message
        )

        // Pick the user's chosen voice, falling back to nova if the stored
        // string is unrecognized (e.g., stale data from a previous install).
        let voice = OpenAITTSService.Voice(rawValue: profile.ttsVoice) ?? .nova

        let data: Data
        do {
            data = try await tts.synthesize(text: script, voice: voice, format: .wav)
        } catch {
            return nil
        }

        // Write to Library/Sounds/. Create the directory first — it doesn't
        // exist by default in a fresh container.
        do {
            try FileManager.default.createDirectory(
                at: Self.soundsDirectory(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: .atomic)
            return filename
        } catch {
            return nil
        }
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
    /// user picks a new voice, so the next refresh definitely re-generates
    /// rather than reusing yesterday's file.
    func invalidateAll() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: Self.soundsDirectory(),
            includingPropertiesForKeys: nil
        ) else {
            return
        }
        for url in contents where url.lastPathComponent.hasPrefix("morning-") {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// The filename `AlarmKitScheduler` should pass to AlarmKit, OR `nil` if
    /// no rendered file exists on disk yet. Lets the scheduler stay sync.
    static func existingRenderedFilename(for alarm: Alarm) -> String? {
        let filename = filename(for: alarm)
        let url = soundsDirectory().appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path) ? filename : nil
    }

    // MARK: - Helpers

    /// Build the full spoken script. Joins segments with paragraph breaks
    /// so the TTS engine treats them as natural pauses instead of running
    /// sentences together. Trims the combined text to `maxWords` so the
    /// audio stays comfortably under the 30-second sound cap.
    private func composeScript(
        name: String,
        affirmations: [Affirmation],
        closing: String?
    ) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let greeting = trimmedName.isEmpty
            ? "Good morning."
            : "Good morning, \(trimmedName)."

        // Take the first three affirmations — anything beyond that pushes the
        // audio past the cap. Priority favorites land at index 0 so they
        // naturally win.
        let lines = affirmations.prefix(3).map { $0.text }

        let closingText = (closing?.isEmpty == false ? closing! : "Have a wonderful day.")

        var segments: [String] = [greeting]
        segments.append(contentsOf: lines)
        segments.append(closingText)

        let joined = segments.joined(separator: "\n\n")
        return trimToWordBudget(joined)
    }

    /// Hard cap on word count. If the affirmations are unusually long, drop
    /// trailing words rather than let AlarmKit truncate the clip at the 30s
    /// boundary. This is a safety net — normal Claude output (~12 words per
    /// affirmation) fits without trimming.
    private func trimToWordBudget(_ text: String) -> String {
        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        guard words.count > maxWords else { return text }
        return words.prefix(maxWords).joined(separator: " ") + "."
    }

    private static func filename(for alarm: Alarm) -> String {
        "morning-\(alarm.id.uuidString).wav"
    }

    private static func soundsDirectory() -> URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return library.appendingPathComponent("Sounds", isDirectory: true)
    }
}
