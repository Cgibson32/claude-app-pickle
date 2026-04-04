import UserNotifications

extension Notification.Name {
    static let didTapAlarmNotification = Notification.Name("didTapAlarmNotification")
    static let didTapEveningReflection = Notification.Name("didTapEveningReflection")
    static let didRequestSnooze = Notification.Name("didRequestSnooze")
}

@MainActor
class NotificationDelegate: NSObject, @preconcurrency UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

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

        switch response.actionIdentifier {
        case "SNOOZE_ACTION":
            NotificationCenter.default.post(name: .didRequestSnooze, object: nil)
        case "REFLECT_ACTION":
            NotificationCenter.default.post(name: .didTapEveningReflection, object: nil)
        case UNNotificationDefaultActionIdentifier:
            if category == "ALARM_CATEGORY" {
                NotificationCenter.default.post(name: .didTapAlarmNotification, object: nil)
            } else if category == "EVENING_REFLECTION_CATEGORY" {
                NotificationCenter.default.post(name: .didTapEveningReflection, object: nil)
            }
        default:
            if category == "ALARM_CATEGORY" {
                NotificationCenter.default.post(name: .didTapAlarmNotification, object: nil)
            }
        }

        completionHandler()
    }
}
