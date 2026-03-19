import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        registerNotificationCategories()
        return true
    }

    private func registerNotificationCategories() {
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Rise & Shine",
            options: .foreground
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze (9 min)",
            options: []
        )
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [dismissAction, snoozeAction],
            intentIdentifiers: []
        )

        let reflectAction = UNNotificationAction(
            identifier: "REFLECT_ACTION",
            title: "Reflect",
            options: .foreground
        )
        let eveningCategory = UNNotificationCategory(
            identifier: "EVENING_REFLECTION_CATEGORY",
            actions: [reflectAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory, eveningCategory])
    }
}
