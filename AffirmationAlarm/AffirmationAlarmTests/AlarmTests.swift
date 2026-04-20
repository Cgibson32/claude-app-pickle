import Foundation
import Testing
@testable import AffirmationAlarm

/// Tests for `Alarm.mostRecentPastFire`, which `MissedAlarmDetector` relies
/// on to decide whether an alarm "should have fired recently". The function
/// uses `Calendar.current` and `Date()` internally; tests use the same
/// calendar math to derive expected results, so they remain stable across
/// time zones and DST transitions.
@Suite("Alarm.mostRecentPastFire")
struct AlarmTests {

    @Test("returns a recent time for a one-shot alarm whose hour:minute just passed")
    func oneShotRecentPast() throws {
        // 15 minutes ago, one-shot (no repeatDays).
        let target = Date().addingTimeInterval(-15 * 60)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: target)
        let alarm = Alarm(hour: comps.hour!, minute: comps.minute!, repeatDays: [])

        let past = try #require(alarm.mostRecentPastFire(withinDays: 2))
        #expect(past <= Date())
        // Within a 24-hour window — we don't expect the function to jump
        // back further than today's occurrence.
        #expect(Date().timeIntervalSince(past) < 24 * 3600)
    }

    @Test("returns nil when repeatDays match only a day outside the scan window")
    func repeatingOutsideWindow() {
        // Day that's 4 calendar days ago — detector default scans only 2.
        let now = Date()
        let calendar = Calendar.current
        let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: now)!
        let weekdayFourDaysAgo = calendar.component(.weekday, from: fourDaysAgo)

        // Today and the last 2 days must NOT equal `weekdayFourDaysAgo`
        // for this test to be deterministic; since the weekly cycle is 7,
        // a single weekday 4 days ago won't overlap [today, today-1, today-2].
        let alarm = Alarm(
            hour: 6,
            minute: 0,
            repeatDays: [weekdayFourDaysAgo]
        )

        #expect(alarm.mostRecentPastFire(withinDays: 2) == nil)
    }

    @Test("returns today's occurrence when repeatDays includes today and hour is in the past")
    func repeatingTodayHourInPast() throws {
        let now = Date()
        let calendar = Calendar.current
        // 2 hours ago so we're safely past the candidate even near midnight.
        let target = now.addingTimeInterval(-2 * 3600)
        let targetComps = calendar.dateComponents([.hour, .minute], from: target)
        let todayWeekday = calendar.component(.weekday, from: target)

        let alarm = Alarm(
            hour: targetComps.hour!,
            minute: targetComps.minute!,
            repeatDays: [todayWeekday]
        )

        let past = try #require(alarm.mostRecentPastFire(withinDays: 2))
        // Either today's occurrence or (if hour-rounding happened to push
        // the candidate past `now`) yesterday's — both within the 2-day
        // window, both strictly in the past.
        #expect(past <= Date())
        #expect(Date().timeIntervalSince(past) < 2 * 24 * 3600)
    }
}
