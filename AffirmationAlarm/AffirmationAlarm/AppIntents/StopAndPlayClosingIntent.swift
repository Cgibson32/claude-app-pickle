import AlarmKit
import AppIntents
import Foundation

/// Handles the "Stop" button on the AlarmKit ringing UI.
///
/// ## Behavior on iOS 26.3.1
///
/// We set `openAppWhenRun = true` so tapping Stop **deterministically**
/// foregrounds the app. This guarantees that the foreground retry in
/// `AffirmationAlarmApp.checkPendingMorningPlayback` always runs, where
/// audio session activation is reliable. The user ends up looking at
/// the app post-alarm anyway — that's the desired morning experience —
/// so there's no UX cost to flipping this on.
///
/// Pipeline:
///
/// 1. Intent cancels the AlarmKit alarm (silences the system tone).
/// 2. Intent writes the alarm ID to `UserDefaults` as a handoff key.
/// 3. Intent attempts background playback via `AlarmAudioPlayer`. If
///    the sandboxed audio session can't start (common on 26.3.1),
///    playback returns `.audioSessionUnavailable` and we exit quietly.
/// 4. iOS foregrounds the app because `openAppWhenRun = true`.
/// 5. `AffirmationAlarmApp.checkPendingMorningPlayback` sees the
///    handoff key and calls `AlarmAudioPlayer.playMorningAndClosing`
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

    /// `true` on purpose: iOS 26.1's "open the app anyway" side-effect
    /// is unreliable on 26.3.1, and the foreground retry is the only
    /// path proven to always have a working audio session. Opening the
    /// app is the desired morning experience anyway.
    static let openAppWhenRun: Bool = true

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

        DiagnosticsLog.shared.log("intent", "stop perform start \(uuid.uuidString.prefix(8))")

        // Silence the system alert immediately.
        try? AlarmManager.shared.cancel(id: uuid)

        // Write the handoff so foreground scenePhase can re-attempt if
        // this sandboxed context fails. Safe to set unconditionally —
        // the actor deduplicates.
        UserDefaults.standard.set(uuid.uuidString, forKey: PendingPlayback.userDefaultsKey)

        // Best-effort background playback. If the sandbox blocks the
        // audio session, `openAppWhenRun = true` guarantees the app
        // foregrounds and the `checkPendingMorningPlayback` retry runs.
        let outcome = await AlarmAudioPlayer.shared.playMorningAndClosing(for: uuid)
        DiagnosticsLog.shared.log("intent", "stop perform done outcome=\(outcome)")

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
