import UserNotifications

enum EveningReflectionSchedulingService {
    private static let identifier = "evening-reflection-daily"

    static func schedule(hour: Int, minute: Int) {
        cancel()

        let content = UNMutableNotificationContent()
        content.title = "Evening Reflection"
        content.body = "Take a moment to reflect on your day"
        content.categoryIdentifier = "EVENING_REFLECTION_CATEGORY"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                AppLogger.alarm.error("evening reflection schedule failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
