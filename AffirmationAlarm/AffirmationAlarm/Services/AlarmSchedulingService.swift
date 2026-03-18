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

        // Primary notification
        let primaryId = "\(alarm.id.uuidString)-\(idSuffix)-primary"
        let primaryContent = makeNotificationContent(alarm: alarm, isFollowUp: false)
        let primaryTrigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: repeats)
        let primaryRequest = UNNotificationRequest(identifier: primaryId, content: primaryContent, trigger: primaryTrigger)

        center.add(primaryRequest) { error in
            if let error {
                print("Failed to schedule primary notification: \(error)")
            }
        }
        identifiers.append(primaryId)

        // Follow-up notification (35 seconds later) for "rings twice" effect
        let followUpId = "\(alarm.id.uuidString)-\(idSuffix)-followup"
        let followUpContent = makeNotificationContent(alarm: alarm, isFollowUp: true)

        // For the follow-up, use a time interval from the calendar trigger
        // We schedule it as a separate calendar trigger offset by adding seconds
        var followUpComponents = triggerComponents
        let currentSecond = triggerComponents.second ?? 0
        followUpComponents.second = currentSecond + Int(AppConstants.secondNotificationDelay)
        // Handle minute overflow
        if let sec = followUpComponents.second, sec >= 60 {
            followUpComponents.second = sec - 60
            followUpComponents.minute = (followUpComponents.minute ?? 0) + 1
            if let min = followUpComponents.minute, min >= 60 {
                followUpComponents.minute = min - 60
                followUpComponents.hour = (followUpComponents.hour ?? 0) + 1
            }
        }

        let followUpTrigger = UNCalendarNotificationTrigger(dateMatching: followUpComponents, repeats: repeats)
        let followUpRequest = UNNotificationRequest(identifier: followUpId, content: followUpContent, trigger: followUpTrigger)

        center.add(followUpRequest) { error in
            if let error {
                print("Failed to schedule follow-up notification: \(error)")
            }
        }
        identifiers.append(followUpId)

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
