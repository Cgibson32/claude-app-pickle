import AlarmKit
import AppIntents
import Foundation

/// Handles the "Snooze" button on the AlarmKit ringing UI.
///
/// Exactly like snoozing a physical alarm clock: the current ring stops,
/// the app doesn't open (`openAppWhenRun = false`), and a fresh follow-up
/// alarm is scheduled 10 minutes from now with no further snooze option.
///
/// The follow-up uses `.default` for its alarm sound because we haven't
/// pre-rendered audio for the fresh follow-up UUID. When the user slides
/// Stop on the follow-up, `StopAndPlayClosingIntent` runs,
/// `AlarmAudioPlayer` finds no rendered files for that UUID and returns
/// `.noFiles`, and the alarm dismisses silently. That's intentional —
/// users don't want a full affirmation sequence from the snooze follow-up.
struct SnoozeMorningIntent: LiveActivityIntent {

    // MARK: - Intent metadata

    static let title: LocalizedStringResource = "Snooze"
    static let description = IntentDescription("Snooze for 10 minutes.")
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
