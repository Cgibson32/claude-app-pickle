import Foundation
import UserNotifications

class EveningReflectionSchedulingService {
    static let shared = EveningReflectionSchedulingService()

    private let notificationIdentifier = "evening-reflection-daily"
    private let categoryIdentifier = "EVENING_REFLECTION_CATEGORY"

    func scheduleEveningNotification(hour: Int, minute: Int) {
        cancelEveningNotification()

        let content = UNMutableNotificationContent()
        content.title = "Evening Reflection"
        content.body = "Take a moment to reflect on your day and practice gratitude."
        content.categoryIdentifier = categoryIdentifier
        content.sound = .default
        content.interruptionLevel = .active

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule evening reflection: \(error)")
            }
        }
    }

    func cancelEveningNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }
}
