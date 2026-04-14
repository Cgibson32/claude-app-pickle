import AlarmKit
import AppIntents
import Foundation

/// Handles the "Stop" button on the AlarmKit ringing UI.
///
/// ## Behavior on iOS 26.3.1
///
/// On iOS 26.1+, sliding Stop reopens the app *even when*
/// `openAppWhenRun = false` — this is an AlarmKit framework behavior, not
/// something we can disable. We take advantage of it:
///
/// 1. The intent cancels the alarm and writes the alarm ID to a
///    `UserDefaults` handoff key.
/// 2. The intent attempts background playback via `AlarmAudioPlayer`.
///    If the intent's sandboxed audio session can't start (which happens
///    intermittently on 26.3.1), the playback call returns
///    `.audioSessionUnavailable` and we exit quietly.
/// 3. When the app finishes launching, `AffirmationAlarmApp.checkPending…`
///    sees the handoff key and calls `AlarmAudioPlayer.playMorningAndClosing`
///    again from the foreground — where audio sessions always work.
///
/// The `AlarmAudioPlayer` actor deduplicates: whichever path activated
/// the audio first "wins" and the other gets `.alreadyPlaying` /
/// `.alreadyPlayed`. The user hears their affirmations exactly once.
struct StopAndPlayClosingIntent: LiveActivityIntent {

    // MARK: - Intent metadata
    //
    // Protocol requirements are declared `{ get }`; `let` satisfies them
    // and keeps the static shared state concurrency-safe under Swift 6.

    static let title: LocalizedStringResource = "Stop"
    static let description = IntentDescription("Stop the alarm and play the closing message.")
    static let openAppWhenRun: Bool = false

    // MARK: - Parameters

    @Parameter(title: "alarmID")
    var alarmID: String

    // MARK: - Init

    init() {
        self.alarmID = ""
    }

    init(alarmID: UUID) {
        self.alarmID = alarmID.uuidString
    }

    // MARK: - Perform

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else { return .result() }

        // Silence the system alert immediately.
        try? AlarmManager.shared.cancel(id: uuid)

        // Write the handoff so foreground scenePhase can re-attempt if
        // this sandboxed context fails. Safe to set unconditionally —
        // the actor deduplicates.
        UserDefaults.standard.set(uuid.uuidString, forKey: PendingPlayback.userDefaultsKey)

        // Best-effort background playback. If the sandbox blocks the
        // audio session, foreground picks it up.
        _ = await AlarmAudioPlayer.shared.playMorningAndClosing(for: uuid)

        return .result()
    }
}

// MARK: - Handoff key

/// Namespaces the `UserDefaults` key shared between the intent and
/// `AffirmationAlarmApp.checkPendingMorningPlayback`. Extracting the
/// string into a single named constant prevents drift.
enum PendingPlayback {
    static let userDefaultsKey = "pendingMorningPlayback"
}
