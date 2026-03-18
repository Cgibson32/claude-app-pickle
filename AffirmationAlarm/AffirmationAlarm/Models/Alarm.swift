import Foundation
import SwiftData

@Model
final class Alarm {
    @Attribute(.unique) var id: UUID
    var hour: Int
    var minute: Int
    var repeatDays: [Int] // 1=Sunday, 2=Monday, ..., 7=Saturday (Calendar weekday)
    var isEnabled: Bool
    var soundName: String
    var label: String
    var notificationIdentifiers: [String]

    init(
        id: UUID = UUID(),
        hour: Int = 6,
        minute: Int = 30,
        repeatDays: [Int] = [2, 3, 4, 5, 6], // Mon-Fri
        isEnabled: Bool = true,
        soundName: String = "alarm_gentle",
        label: String = "Morning Alarm",
        notificationIdentifiers: [String] = []
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
        self.soundName = soundName
        self.label = label
        self.notificationIdentifiers = notificationIdentifiers
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? .now
        return formatter.string(from: date)
    }

    var repeatDaysString: String {
        if repeatDays.isEmpty { return "One time" }
        if repeatDays.count == 7 { return "Every day" }

        let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sorted = repeatDays.sorted()
        if sorted == [2, 3, 4, 5, 6] { return "Weekdays" }
        if sorted == [1, 7] { return "Weekends" }

        return sorted.map { weekdaySymbols[$0 - 1] }.joined(separator: ", ")
    }

    var nextFireDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        components.second = 0

        if repeatDays.isEmpty {
            // One-time alarm: find next occurrence of this time
            components.year = calendar.component(.year, from: now)
            components.month = calendar.component(.month, from: now)
            components.day = calendar.component(.day, from: now)
            if let date = calendar.date(from: components), date > now {
                return date
            }
            // If time has passed today, schedule for tomorrow
            components.day! += 1
            return calendar.date(from: components)
        }

        // Find the nearest upcoming day
        var bestDate: Date?
        for dayOffset in 0..<7 {
            guard let candidate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let weekday = calendar.component(.weekday, from: candidate)
            guard repeatDays.contains(weekday) else { continue }

            components.year = calendar.component(.year, from: candidate)
            components.month = calendar.component(.month, from: candidate)
            components.day = calendar.component(.day, from: candidate)

            guard let fireDate = calendar.date(from: components) else { continue }
            if fireDate > now {
                bestDate = fireDate
                break
            }
        }
        return bestDate
    }
}
