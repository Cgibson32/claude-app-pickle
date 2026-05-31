import UserNotifications

/// Handles taps on the evening-reflection reminder and the backup alarm
/// notification's Stop/Snooze action buttons.
@MainActor
class NotificationDelegate: NSObject, @preconcurrency UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    static let alarmCategoryID = "ALARM_BACKUP_CATEGORY"
    static let stopActionID = "ALARM_STOP_ACTION"
    static let snoozeActionID = "ALARM_SNOOZE_ACTION"

    func registerCategories() {
        let stop = UNNotificationAction(
            identifier: Self.stopActionID,
            title: "Stop",
            options: [.foreground]
        )
        let snooze = UNNotificationAction(
            identifier: Self.snoozeActionID,
            title: "Snooze",
            options: []
        )
        let alarmCategory = UNNotificationCategory(
            identifier: Self.alarmCategoryID,
            actions: [stop, snooze],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let reflectionCategory = UNNotificationCategory(
            identifier: "EVENING_REFLECTION_CATEGORY",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            alarmCategory,
            reflectionCategory
        ])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let category = response.notification.request.content.categoryIdentifier

        if category == "EVENING_REFLECTION_CATEGORY" {
            NotificationCenter.default.post(name: .didTapEveningReflection, object: nil)
        }

        if category == Self.alarmCategoryID {
            let alarmIDString = response.notification.request.content.userInfo["alarmID"] as? String ?? ""
            let alarmID = UUID(uuidString: alarmIDString)

            switch response.actionIdentifier {
            case Self.stopActionID:
                if let alarmID {
                    PendingPlayback.write(alarmID: alarmID)
                    DiagnosticsLog.shared.log("notification", "Stop tapped on backup notification — pending playback for \(alarmIDString.prefix(8))")
                }
            case Self.snoozeActionID:
                if alarmID != nil {
                    UserDefaults.standard.set(alarmIDString, forKey: "pendingSnoozeRescheduleAlarmID")
                    DiagnosticsLog.shared.log("notification", "Snooze tapped on backup notification — pending snooze for \(alarmIDString.prefix(8))")
                }
            default:
                if let alarmID {
                    PendingPlayback.write(alarmID: alarmID)
                }
            }
        }

        completionHandler()
    }
}
