import Foundation

/// Tracks consecutive successful alarm-completion days. Drives the
/// "X mornings in a row" ribbon on Home. Pure logic + UserDefaults
/// persistence, no SwiftData.
///
/// A "successful day" = at least one alarm fire that the user
/// acknowledged (Stop or Snooze). Idempotent within the day —
/// multiple alarms or multiple snoozes don't stack.
enum StreakService {

    private static let userDefaultsKey = "com.cgibson.affirmationalarm.streak.successDays"

    /// Mark today (or `date`) as a success. Stored as the start-of-day
    /// timestamp so duplicates merge naturally.
    static func recordSuccess(date: Date = Date()) {
        let day = Calendar.current.startOfDay(for: date)
        var days = persistedDays()
        if !days.contains(day) {
            days.insert(day)
            persist(days: days)
        }
    }

    /// Number of consecutive days (counting back from the most recent
    /// success) that have a recorded success. The streak is "alive" only
    /// if the most recent day is today or yesterday — give a one-day
    /// grace so users who open the app late still see their run.
    static func currentStreak(now: Date = Date()) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today) ?? today

        let days = persistedDays()
        guard let mostRecent = days.max() else { return 0 }
        guard mostRecent >= yesterday else { return 0 }

        var streak = 0
        var cursor = mostRecent
        while days.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    // MARK: - Persistence

    private static func persistedDays() -> Set<Date> {
        let stamps = UserDefaults.standard.array(forKey: userDefaultsKey) as? [Double] ?? []
        return Set(stamps.map { Date(timeIntervalSince1970: $0) })
    }

    private static func persist(days: Set<Date>) {
        let stamps = days.map { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(stamps, forKey: userDefaultsKey)
    }
}
