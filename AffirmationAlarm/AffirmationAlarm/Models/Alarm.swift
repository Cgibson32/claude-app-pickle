import Foundation
import SwiftData

@Model
final class Alarm {
    var id: UUID = UUID()
    var hour: Int = 6
    var minute: Int = 30
    var isEnabled: Bool = true
    var soundName: String = "alarm_gentle"
    var label: String = "Morning Affirmations"
    var repeatDaysData: String = "[2,3,4,5,6]"
    var notificationIdentifiersData: String = "[]"

    var repeatDays: [Int] {
        get {
            (try? JSONDecoder().decode([Int].self, from: Data(repeatDaysData.utf8))) ?? []
        }
        set {
            repeatDaysData = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    var notificationIdentifiers: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: Data(notificationIdentifiersData.utf8))) ?? []
        }
        set {
            notificationIdentifiersData = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    init(hour: Int = 6, minute: Int = 30, repeatDays: [Int] = [2, 3, 4, 5, 6], isEnabled: Bool = true, soundName: String = "alarm_gentle", label: String = "Morning Affirmations") {
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
        self.soundName = soundName
        self.label = label
        self.repeatDays = repeatDays
    }

    var timeString: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", h, minute, period)
    }

    var repeatDaysString: String {
        let days = repeatDays.sorted()
        if days == [1, 2, 3, 4, 5, 6, 7] { return "Every day" }
        if days == [2, 3, 4, 5, 6] { return "Weekdays" }
        if days == [1, 7] { return "Weekends" }
        let names = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days.map { names[$0] }.joined(separator: ", ")
    }

    var nextFireDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let days = repeatDays.sorted()
        if days.isEmpty {
            components.year = calendar.component(.year, from: now)
            components.month = calendar.component(.month, from: now)
            components.day = calendar.component(.day, from: now)
            if let date = calendar.date(from: components), date > now {
                return date
            }
            return calendar.date(byAdding: .day, value: 1, to: calendar.date(from: components) ?? now)
        }

        let currentWeekday = calendar.component(.weekday, from: now)
        for offset in 0..<7 {
            let targetWeekday = ((currentWeekday - 1 + offset) % 7) + 1
            if days.contains(targetWeekday) {
                components.weekday = targetWeekday
                if let date = calendar.nextDate(after: offset == 0 ? now : calendar.startOfDay(for: now), matching: components, matchingPolicy: .nextTime) {
                    return date
                }
            }
        }
        return nil
    }
}
