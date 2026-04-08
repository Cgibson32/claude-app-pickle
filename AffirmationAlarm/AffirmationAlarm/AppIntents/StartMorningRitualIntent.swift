import AlarmKit
import AppIntents
import Foundation

/// App Intent wired up as the `stopIntent` on every scheduled AlarmKit alarm.
/// When the user taps the alarm's "Start Ritual" stop button, the system:
///
/// 1. Stops the alarm via AlarmKit (`AlarmManager.cancel(id:)`).
/// 2. Launches this app into the foreground (`openAppWhenRun = true`).
/// 3. Runs `perform()`, which posts `.didTapAlarmNotification` so
///    `RootView.onReceive` can present the full `AffirmationSequenceView`.
///
/// The intent cold-launches the app reliably because AlarmKit guarantees the
/// scene is active before `perform()` runs — there's no cold-launch race
/// condition to handle here like there was under `UNUserNotificationCenter`.
struct StartMorningRitualIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Start Morning Ritual"
    static var description = IntentDescription("Dismiss the alarm and begin your affirmation sequence.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: UUID) {
        self.alarmID = alarmID.uuidString
    }

    init() {
        self.alarmID = ""
    }

    func perform() async throws -> some IntentResult {
        // Stop the underlying alarm if the id is valid. We swallow errors
        // because the alarm may have already been cancelled by the system
        // (one-shot fire, user deleted the alarm in-app, etc.) and that
        // should not block launching the ritual.
        if let uuid = UUID(uuidString: alarmID) {
            try? AlarmManager.shared.cancel(id: uuid)
        }

        // Hop onto the main actor to post the notification SwiftUI listens
        // for. `NotificationCenter.post` itself is thread-safe, but we keep
        // the hop explicit so downstream observers don't have to worry
        // about their execution context.
        await MainActor.run {
            NotificationCenter.default.post(name: .didTapAlarmNotification, object: nil)
        }

        return .result()
    }
}
