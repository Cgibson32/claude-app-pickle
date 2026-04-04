import UserNotifications

@MainActor @Observable
class AlarmSchedulingService {
    static let shared = AlarmSchedulingService()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleAlarm(_ alarm: Alarm) {
        cancelAlarm(alarm)
        guard alarm.isEnabled else { return }

        // Skip scheduling if notifications aren't authorized
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            guard settings.authorizationStatus == .authorized else { return }
            self.scheduleNotifications(for: alarm)
        }
    }

    private func scheduleNotifications(for alarm: Alarm) {

        let days = alarm.repeatDays.sorted()
        var identifiers: [String] = []

        if days.isEmpty {
            let id = "alarm-\(alarm.id.uuidString)"
            let content = makeContent(for: alarm)
            var components = DateComponents()
            components.hour = alarm.hour
            components.minute = alarm.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
            identifiers.append(id)
        } else {
            for day in days {
                let id = "alarm-\(alarm.id.uuidString)-\(day)"
                let content = makeContent(for: alarm)
                var components = DateComponents()
                components.hour = alarm.hour
                components.minute = alarm.minute
                components.weekday = day
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
                identifiers.append(id)
            }
        }

        alarm.notificationIdentifiers = identifiers
    }

    func cancelAlarm(_ alarm: Alarm) {
        let ids = alarm.notificationIdentifiers
        if !ids.isEmpty {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
        alarm.notificationIdentifiers = []
    }

    func scheduleSnooze(for alarm: Alarm) {
        let id = "snooze-\(UUID().uuidString)"
        let content = makeContent(for: alarm)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(AppConstants.snoozeDurationMinutes * 60),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func makeContent(for alarm: Alarm) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = alarm.label.isEmpty ? "Morning Affirmations" : alarm.label
        content.body = "Time for your daily affirmations"
        content.categoryIdentifier = "ALARM_CATEGORY"

        if Bundle.main.url(forResource: alarm.soundName, withExtension: "caf") != nil {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(alarm.soundName).caf"))
        } else {
            content.sound = .default
        }

        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        return content
    }
}
