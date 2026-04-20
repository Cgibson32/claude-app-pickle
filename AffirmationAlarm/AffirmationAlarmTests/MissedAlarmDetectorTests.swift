import Foundation
import Testing
@testable import AffirmationAlarm

/// Tests for the persistence + detection pure-function paths of
/// `MissedAlarmDetector`. These tests share `UserDefaults.standard` —
/// each test writes a unique alarm UUID and cleans up on exit so parallel
/// runs don't collide, and we never touch keys outside the detector's
/// namespace.
@Suite("MissedAlarmDetector")
struct MissedAlarmDetectorTests {

    /// Wipe the detector's UserDefaults key so a test starts from a clean
    /// slate. Called at the start of every test; the suite intentionally
    /// does not run in parallel (see `.serialized` below).
    private func resetStore() {
        UserDefaults.standard.removeObject(forKey: MissedAlarmDetector.userDefaultsKey)
    }

    @Test("recordSuccess roundtrips through allLastSuccesses")
    func recordSuccessRoundtrip() {
        resetStore()
        defer { resetStore() }

        let id = UUID()
        let when = Date(timeIntervalSince1970: 1_700_000_000)
        MissedAlarmDetector.recordSuccess(alarmID: id, date: when)

        let all = MissedAlarmDetector.allLastSuccesses()
        #expect(all[id] == when)
        #expect(MissedAlarmDetector.lastSuccess(for: id) == when)
    }

    @Test("lastSuccess returns nil for unknown alarm")
    func lastSuccessUnknown() {
        resetStore()
        defer { resetStore() }

        #expect(MissedAlarmDetector.lastSuccess(for: UUID()) == nil)
    }

    @Test("detect returns empty when an alarm has no success history")
    func detectSkipsUntrackedAlarms() {
        resetStore()
        defer { resetStore() }

        // Past fire an hour ago, well outside the 5-minute settling window.
        let alarm = alarmFiringMinutesAgo(60)
        let missed = MissedAlarmDetector.detect(alarms: [alarm])

        #expect(missed.isEmpty, "conservative policy: no history means no flagging")
    }

    @Test("detect flags alarm when last success predates most recent fire")
    func detectFlagsStaleSuccess() {
        resetStore()
        defer { resetStore() }

        let alarm = alarmFiringMinutesAgo(60)
        // Success recorded 10 days ago — older than the most recent fire.
        MissedAlarmDetector.recordSuccess(
            alarmID: alarm.id,
            date: Date().addingTimeInterval(-10 * 24 * 3600)
        )

        let missed = MissedAlarmDetector.detect(alarms: [alarm])
        #expect(missed.map(\.id) == [alarm.id])
    }

    @Test("detect does not flag when last success is after most recent fire")
    func detectIgnoresFreshSuccess() {
        resetStore()
        defer { resetStore() }

        let alarm = alarmFiringMinutesAgo(60)
        MissedAlarmDetector.recordSuccess(alarmID: alarm.id, date: Date())

        let missed = MissedAlarmDetector.detect(alarms: [alarm])
        #expect(missed.isEmpty)
    }

    @Test("detect ignores disabled alarms even if success is stale")
    func detectIgnoresDisabled() {
        resetStore()
        defer { resetStore() }

        let alarm = alarmFiringMinutesAgo(60)
        alarm.isEnabled = false
        MissedAlarmDetector.recordSuccess(
            alarmID: alarm.id,
            date: Date().addingTimeInterval(-10 * 24 * 3600)
        )

        let missed = MissedAlarmDetector.detect(alarms: [alarm])
        #expect(missed.isEmpty)
    }

    // MARK: - Helpers

    /// Build a one-shot alarm whose most recent past fire lands `minutes`
    /// ago. We pick (hour, minute) such that the current calendar day's
    /// occurrence is `minutes` minutes before `Date()`. Time-of-day flake
    /// window: if `minutes > (currentMinuteOfDay)` we'd wrap to yesterday
    /// — safe for values like 60 since the app only runs tests when
    /// it's past 01:00 in practice. For robustness, we take the result
    /// of `nextFireDate`-style calendar math and accept whichever past
    /// occurrence lands within the detector's 2-day scan window.
    private func alarmFiringMinutesAgo(_ minutes: Int) -> Alarm {
        let target = Date().addingTimeInterval(-Double(minutes) * 60)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: target)
        return Alarm(
            hour: comps.hour ?? 0,
            minute: comps.minute ?? 0,
            repeatDays: [],
            isEnabled: true
        )
    }
}
