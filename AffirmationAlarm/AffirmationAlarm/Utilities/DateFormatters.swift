import Foundation

enum AppDateFormatters {
    static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func relativeAlarmTime(from date: Date) -> String {
        let now = Date()
        let interval = date.timeIntervalSince(now)
        if interval < 0 { return "now" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours == 0 {
            return "in \(minutes)m"
        } else if hours < 24 {
            return minutes > 0 ? "in \(hours)h \(minutes)m" : "in \(hours)h"
        } else {
            let days = hours / 24
            return days == 1 ? "tomorrow" : "in \(days) days"
        }
    }

    static func dayKey(for date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }

    static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}
