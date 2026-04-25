import Foundation
import Testing
@testable import AffirmationAlarm

@Suite("StreakService")
struct StreakServiceTests {

    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_750_000_000)

    private func daysAgo(_ n: Int) -> Date {
        calendar.date(byAdding: .day, value: -n, to: now)!
    }

    @Test("no successes returns empty streak")
    func noSuccesses() {
        let streak = StreakService.compute(from: [], now: now, calendar: calendar)
        #expect(streak.count == 0)
        #expect(streak.isLive == false)
    }

    @Test("single success today is a live streak of one")
    func singleSuccessToday() {
        let streak = StreakService.compute(from: [now], now: now, calendar: calendar)
        #expect(streak.count == 1)
        #expect(streak.isLive == true)
    }

    @Test("five consecutive days ending today is live")
    func fiveConsecutiveDays() {
        let dates = (0..<5).map { daysAgo($0) }
        let streak = StreakService.compute(from: dates, now: now, calendar: calendar)
        #expect(streak.count == 5)
        #expect(streak.isLive == true)
    }

    @Test("streak ending yesterday is still live")
    func yesterdayIsLive() {
        let dates = [daysAgo(1), daysAgo(2), daysAgo(3)]
        let streak = StreakService.compute(from: dates, now: now, calendar: calendar)
        #expect(streak.count == 3)
        #expect(streak.isLive == true)
    }

    @Test("streak ending two days ago is paused")
    func twoDaysAgoIsPaused() {
        let dates = [daysAgo(2), daysAgo(3), daysAgo(4)]
        let streak = StreakService.compute(from: dates, now: now, calendar: calendar)
        #expect(streak.count == 3)
        #expect(streak.isLive == false)
    }

    @Test("a gap breaks the streak; only the most recent run counts")
    func gapBreaksStreak() {
        // Today, yesterday, then a gap, then 3 older days.
        let dates = [now, daysAgo(1), daysAgo(4), daysAgo(5), daysAgo(6)]
        let streak = StreakService.compute(from: dates, now: now, calendar: calendar)
        #expect(streak.count == 2)
        #expect(streak.isLive == true)
    }

    @Test("multiple alarms on the same day count once")
    func sameDayDeduplicated() {
        let morning = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: now)!
        let evening = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now)!
        let streak = StreakService.compute(from: [morning, evening], now: now, calendar: calendar)
        #expect(streak.count == 1)
        #expect(streak.isLive == true)
    }
}
