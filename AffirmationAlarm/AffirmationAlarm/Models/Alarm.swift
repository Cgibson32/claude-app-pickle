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
    var repeatDaysData: String = "[]"
    // TODO(v1.1): Remove alongside a proper VersionedSchema migration.
    // Vestigial field — never read, only written to by old scheduler code.
    // Kept to avoid SwiftData schema change that would trigger in-memory
    // fallback and wipe existing alarm data.
    var notificationIdentifiersData: String = "[]"

    var repeatDays: [Int] {
        get {
            (try? JSONDecoder().decode([Int].self, from: Data(repeatDaysData.utf8))) ?? []
        }
        set {
            repeatDaysData = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    init(hour: Int = 6, minute: Int = 30, repeatDays: [Int] = [], isEnabled: Bool = true, soundName: String = "alarm_gentle", label: String = "Morning Affirmations") {
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
        if days.isEmpty { return "Does not repeat" }
        if days == [1, 2, 3, 4, 5, 6, 7] { return "Every day" }
        if days == [2, 3, 4, 5, 6] { return "Weekdays" }
        if days == [1, 7] { return "Weekends" }
        let names = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days.map { names[$0] }.joined(separator: ", ")
    }

    var nextFireDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        let days = Set(repeatDays)

        // Scan today + next 7 days. For each candidate day, build a date at
        // this alarm's hour/minute and return the first one that is both in
        // the future and (for repeating alarms) on an allowed weekday.
        for offset in 0..<8 {
            guard let dayBase = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) else { continue }
            var comps = calendar.dateComponents([.year, .month, .day], from: dayBase)
            comps.hour = hour
            comps.minute = minute
            guard let candidate = calendar.date(from: comps), candidate > now else { continue }

            if days.isEmpty {
                return candidate
            }
            let weekday = calendar.component(.weekday, from: candidate)
            if days.contains(weekday) {
                return candidate
            }
        }
        return nil
    }
}
