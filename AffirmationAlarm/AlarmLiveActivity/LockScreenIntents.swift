import AlarmKit
import AppIntents
import Foundation

/// Stop intent invoked when the user taps the Stop button inside the
/// Live Activity (lock screen / Dynamic Island). Distinct type from the
/// main app's `StopAndPlayClosingIntent` because the widget extension
/// can't directly reference the main app's heavy dependencies — instead
/// we cancel the alarm here, set a UserDefaults handoff key, and the
/// `openAppWhenRun = true` flag activates the main app where
/// `checkPendingMorningPlayback` picks up the handoff and plays the
/// affirmations from a working audio session.
struct StopFromLockScreen: LiveActivityIntent {

    static let title: LocalizedStringResource = "Stop"
    static let description = IntentDescription("Stop the alarm and play your morning affirmations.")
    static let openAppWhenRun: Bool = true

    @Parameter(title: "alarmID")
    var alarmID: String

    init() {
        self.alarmID = ""
    }

    init(alarmID: UUID) {
        self.alarmID = alarmID.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else { return .result() }
        try? AlarmManager.shared.cancel(id: uuid)
        UserDefaults.standard.set("stop", forKey: "lockScreenAction")
        UserDefaults.standard.set(uuid.uuidString, forKey: "pendingMorningPlayback")
        return .result()
    }
}

/// Snooze intent invoked when the user taps the Snooze label inside
/// the Live Activity. Cancels the current alarm, writes a handoff key
/// for the main app's scenePhase observer, and brings the app forward
/// (`openAppWhenRun = true`) so the scheduler can build the snooze
/// follow-up with the user's actual configuration.
struct SnoozeFromLockScreen: LiveActivityIntent {

    static let title: LocalizedStringResource = "Snooze"
    static let description = IntentDescription("Snooze for 9 minutes.")
    static let openAppWhenRun: Bool = true

    @Parameter(title: "alarmID")
    var alarmID: String

    init() {
        self.alarmID = ""
    }

    init(alarmID: UUID) {
        self.alarmID = alarmID.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else { return .result() }
        try? AlarmManager.shared.cancel(id: uuid)
        UserDefaults.standard.set("snooze", forKey: "lockScreenAction")
        UserDefaults.standard.set(uuid.uuidString, forKey: "pendingSnoozeRescheduleAlarmID")
        return .result()
    }
}
