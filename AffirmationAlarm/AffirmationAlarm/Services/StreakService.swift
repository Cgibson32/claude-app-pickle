import Foundation

/// Counts consecutive days the user has woken up to their morning ritual.
///
/// Reads success records written by `AlarmKitScheduler.handleFire` via
/// `MissedAlarmDetector.recordSuccess`. A "streak day" is a calendar day
/// on which any enabled alarm completed successfully (Stop or Snooze
/// both count — both are explicit "I heard it" signals).
///
/// ## Live vs. paused
///
/// The streak is "live" only when the most recent success was today or
/// yesterday. The Home ribbon hides when the streak isn't live — we
/// deliberately never display a "you broke your streak" or "welcome back"
/// message. Silence is gentler than implying absence; the user comes
/// back to a clean slate when the next morning lands.
enum StreakService {

    struct Streak: Sendable, Equatable {
        let count: Int
        let isLive: Bool

        static let none = Streak(count: 0, isLive: false)
    }

    /// Read the user's current streak from disk.
    static func current(now: Date = Date(), calendar: Calendar = .current) -> Streak {
        let dates = Array(MissedAlarmDetector.allLastSuccesses().values)
        return compute(from: dates, now: now, calendar: calendar)
    }

    /// Pure computation, exposed for unit tests.
    static func compute(from successDates: [Date], now: Date, calendar: Calendar) -> Streak {
        let days = Set(successDates.map { calendar.startOfDay(for: $0) })
        guard !days.isEmpty else { return .none }

        let sorted = days.sorted(by: >)
        let mostRecent = sorted[0]
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            return .none
        }
        let isLive = (mostRecent == today || mostRecent == yesterday)

        var count = 1
        var cursor = mostRecent
        for day in sorted.dropFirst() {
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            if day == prev {
                count += 1
                cursor = day
            } else {
                break
            }
        }

        return Streak(count: count, isLive: isLive)
    }
}
