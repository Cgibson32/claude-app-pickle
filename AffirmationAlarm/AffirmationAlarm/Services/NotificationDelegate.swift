import UserNotifications

/// Handles taps on the evening-reflection reminder, which is still a plain
/// `UNUserNotification` (alarms are handled by AlarmKit via
/// `StartMorningRitualIntent`).
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
        if category == "EVENING_REFLECTION_CATEGORY" {
            NotificationCenter.default.post(name: .didTapEveningReflection, object: nil)
        }
        completionHandler()
    }
}
