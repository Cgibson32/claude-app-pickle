import AlarmKit
import AppIntents
import Foundation

/// Handles the "Snooze" button on the AlarmKit system alert.
///
/// Cancels the current alarm, then schedules a snooze follow-up via
/// `AlarmKitScheduler.scheduleSnoozeFollowUp`. The follow-up fires
/// 9 minutes later and plays a short personalized greeting ("Alright,
/// time to get up, [name]!") followed by a random wake-up song from
/// the bundled `WakeUpSongs/` library — no affirmations on snooze.
///
/// Re-snooze is supported: the follow-up gets its own Snooze button.
struct SnoozeMorningIntent: LiveActivityIntent {

    // MARK: - Intent metadata

    static let title: LocalizedStringResource = "Snooze"
    static let description = IntentDescription("Snooze for 9 minutes.")
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

        try? AlarmManager.shared.cancel(id: uuid)

        // Scheduling touches `@MainActor` state on the scheduler, so hop
        // over before invoking it.
        await MainActor.run {
            AlarmKitScheduler.shared.scheduleSnoozeFollowUp(originalAlarmID: uuid)
        }

        return .result()
    }
}
