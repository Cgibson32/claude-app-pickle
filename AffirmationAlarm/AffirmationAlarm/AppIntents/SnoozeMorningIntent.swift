import AlarmKit
import AppIntents
import Foundation

/// Runs when the user taps the Snooze button on the AlarmKit alarm UI.
///
/// `openAppWhenRun = false` keeps the app in the background — snoozing
/// should feel exactly like tapping snooze on a real alarm clock: the
/// ringing stops, nothing opens, and 10 minutes later a follow-up alarm
/// rings with different audio to get you out of bed.
///
/// The intent:
///
/// 1. Cancels the currently ringing alarm via `AlarmManager.cancel(id:)`.
/// 2. Calls back into `AlarmKitScheduler.shared.scheduleSnoozeFollowUp(...)`
///    on the main actor to schedule a new one-shot alarm 10 minutes from now.
///    That follow-up uses the pre-rendered `snooze-<originalAlarmID>.wav`
///    as its alarm sound — the user's selected tone briefly beeping, then
///    the voice saying *"Time to get up, [Name]. Let's have a great day."*
///
/// The follow-up alarm has only a Stop button — no further snoozing.
struct SnoozeMorningIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Snooze"
    static var description = IntentDescription("Snooze for 10 minutes.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: UUID) {
        self.alarmID = alarmID.uuidString
    }

    init() {
        self.alarmID = ""
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else { return .result() }

        try? AlarmManager.shared.cancel(id: uuid)

        await MainActor.run {
            AlarmKitScheduler.shared.scheduleSnoozeFollowUp(originalAlarmID: uuid)
        }

        return .result()
    }
}
