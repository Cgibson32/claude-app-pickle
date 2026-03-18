import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let notificationDelegate = NotificationDelegate.shared
        UNUserNotificationCenter.current().delegate = notificationDelegate
        registerNotificationCategories()
        return true
    }

    private func registerNotificationCategories() {
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Rise & Shine",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze (9 min)",
            options: []
        )

        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [dismissAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }
}
