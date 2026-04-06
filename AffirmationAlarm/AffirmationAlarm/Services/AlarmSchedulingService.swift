import UserNotifications

@MainActor @Observable
class AlarmSchedulingService {
    static let shared = AlarmSchedulingService()

    /// Set to `true` when the user has explicitly denied notification
    /// permission. `AlarmListView` observes this to show a banner.
    var permissionDenied = false

    private init() {}

    // MARK: - Permission

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge, .providesAppNotificationSettings])
            permissionDenied = !granted
            return granted
        } catch {
            permissionDenied = true
            return false
        }
    }

    func refreshPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionDenied = (settings.authorizationStatus == .denied)
    }

    // MARK: - Scheduling

    func scheduleAlarm(_ alarm: Alarm) {
        cancelAlarm(alarm)
        guard alarm.isEnabled else { return }

        Task { [weak self] in
            guard let self else { return }
            let center = UNUserNotificationCenter.current()
            var settings = await center.notificationSettings()

            if settings.authorizationStatus == .notDetermined {
                _ = await self.requestPermission()
                settings = await center.notificationSettings()
            }

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self.permissionDenied = false
                self.scheduleNotifications(for: alarm)
                #if DEBUG
                await self.logPendingRequests()
                #endif
            case .denied:
                self.permissionDenied = true
            default:
                break
            }
        }
    }

    /// Re-arm every enabled alarm. Called on app launch to ensure one-shot
    /// alarms stay queued across relaunches and to self-heal any state drift
    /// between SwiftData and `UNUserNotificationCenter`.
    func rescheduleAll(_ alarms: [Alarm]) {
        for alarm in alarms where alarm.isEnabled {
            scheduleAlarm(alarm)
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

    // MARK: - Debug

    #if DEBUG
    func logPendingRequests() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("[AlarmSchedulingService] Pending notification requests: \(requests.count)")
        for r in requests {
            if let trigger = r.trigger as? UNCalendarNotificationTrigger {
                print("  - \(r.identifier) → next: \(trigger.nextTriggerDate().map { "\($0)" } ?? "nil")")
            } else {
                print("  - \(r.identifier) (\(type(of: r.trigger)))")
            }
        }
    }
    #endif
}
