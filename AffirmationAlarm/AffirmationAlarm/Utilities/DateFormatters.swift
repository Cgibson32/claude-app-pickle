import Foundation

enum DateFormatters {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func dayKey(for date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }

    static func tomorrowDayKey() -> String {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return dayKey(for: tomorrow)
    }

    static func relativeAlarmTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today at \(timeFormatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow at \(timeFormatter.string(from: date))"
        } else {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            return "\(dayFormatter.string(from: date)) at \(timeFormatter.string(from: date))"
        }
    }
}
