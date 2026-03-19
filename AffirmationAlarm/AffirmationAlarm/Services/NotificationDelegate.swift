import Foundation
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificationDelegate()

    @Published var shouldShowAffirmationSequence = false

    // Called when notification arrives while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the notification even when app is in foreground
        completionHandler([.banner, .sound])
    }

    // Called when user interacts with notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let alarmId = userInfo["alarmId"] as? String ?? ""

        let categoryIdentifier = response.notification.request.content.categoryIdentifier

        if categoryIdentifier == "EVENING_REFLECTION_CATEGORY" || response.actionIdentifier == "REFLECT_ACTION" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didTapEveningReflection, object: nil)
            }
        } else {
            switch response.actionIdentifier {
            case "DISMISS_ACTION", UNNotificationDefaultActionIdentifier:
                DispatchQueue.main.async {
                    self.shouldShowAffirmationSequence = true
                    NotificationCenter.default.post(name: .didTapAlarmNotification, object: nil)
                }

            case "SNOOZE_ACTION":
                AlarmSchedulingService.shared.snoozeAlarm(alarmId: alarmId)

            default:
                break
            }
        }

        completionHandler()
    }
}
