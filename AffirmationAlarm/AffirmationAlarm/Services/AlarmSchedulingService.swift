import Foundation
import UserNotifications

@Observable
class AlarmSchedulingService {
    static let shared = AlarmSchedulingService()

    var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    private init() {
        checkAuthorizationStatus()
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                completion(granted)
            }
        }
    }

    func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleAlarm(_ alarm: Alarm) {
        // Remove existing notifications for this alarm
        removeNotifications(for: alarm)

        guard alarm.isEnabled else { return }

        var identifiers: [String] = []

        if alarm.repeatDays.isEmpty {
            // One-time alarm
            let ids = scheduleOneTimeAlarm(alarm)
            identifiers.append(contentsOf: ids)
        } else {
            // Repeating alarm — schedule for each day, for the next 7 days
            for day in alarm.repeatDays {
                let ids = scheduleRepeatingAlarm(alarm, weekday: day)
                identifiers.append(contentsOf: ids)
            }
        }

        alarm.notificationIdentifiers = identifiers
    }

    func removeNotifications(for alarm: Alarm) {
        center.removePendingNotificationRequests(withIdentifiers: alarm.notificationIdentifiers)
        alarm.notificationIdentifiers = []
    }

    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    func rescheduleAllAlarms(_ alarms: [Alarm]) {
        removeAllNotifications()
        for alarm in alarms where alarm.isEnabled {
            scheduleAlarm(alarm)
        }
    }

    // MARK: - Private

    private func scheduleOneTimeAlarm(_ alarm: Alarm) -> [String] {
        var components = DateComponents()
        components.hour = alarm.hour
        components.minute = alarm.minute

        return scheduleNotificationPair(
            alarm: alarm,
            triggerComponents: components,
            repeats: false,
            idSuffix: "onetime"
        )
    }

    private func scheduleRepeatingAlarm(_ alarm: Alarm, weekday: Int) -> [String] {
        var components = DateComponents()
        components.hour = alarm.hour
        components.minute = alarm.minute
        components.weekday = weekday

        return scheduleNotificationPair(
            alarm: alarm,
            triggerComponents: components,
            repeats: true,
            idSuffix: "day\(weekday)"
        )
    }

    private func scheduleNotificationPair(
        alarm: Alarm,
        triggerComponents: DateComponents,
        repeats: Bool,
        idSuffix: String
    ) -> [String] {
        var identifiers: [String] = []

        // Single notification — alarm sound plays for 10 seconds in-app when user taps
        let notificationId = "\(alarm.id.uuidString)-\(idSuffix)"
        let content = makeNotificationContent(alarm: alarm, isFollowUp: false)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: repeats)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error)")
            }
        }
        identifiers.append(notificationId)

        return identifiers
    }

    private func makeNotificationContent(alarm: Alarm, isFollowUp: Bool) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = isFollowUp ? "Time to Rise!" : "Good Morning!"
        content.body = isFollowUp
            ? "Your affirmations are waiting for you. Tap to start your day with positivity."
            : "Tap to hear your personalized morning affirmations."
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(alarm.soundName).caf"))
        content.userInfo = [
            "alarmId": alarm.id.uuidString,
            "isFollowUp": isFollowUp
        ]
        content.interruptionLevel = .timeSensitive
        return content
    }

    // Snooze support
    func snoozeAlarm(alarmId: String) {
        let snoozeId = "\(alarmId)-snooze"
        let content = UNMutableNotificationContent()
        content.title = "Snooze Over!"
        content.body = "Time for your morning affirmations."
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.sound = .default
        content.userInfo = ["alarmId": alarmId, "isSnooze": true]
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(AppConstants.snoozeMinutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: snoozeId, content: content, trigger: trigger)
        center.add(request)
    }
}
