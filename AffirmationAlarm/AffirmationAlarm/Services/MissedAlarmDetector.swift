import Foundation

/// Tracks the last time each alarm successfully completed and, on launch,
/// surfaces any enabled alarm whose most recent expected fire wasn't
/// recorded as successful.
///
/// Why this exists: AlarmKit, the foreground observer, and the silent
/// keep-alive audio session together are load-bearing. Any one of them
/// failing silently overnight means the user wakes up late with no
/// indication anything went wrong. This detector gives the app a chance
/// to say "hey, something looked off last night, here's the diagnostics
/// log" the next time the user opens it.
///
/// Conservative policy: only flag an alarm as missed if it has at least
/// one successful fire on record. First-time users with no history never
/// see the banner — we don't want to cry wolf before the app has proven
/// it can fire successfully at all.
enum MissedAlarmDetector {

    /// UserDefaults key for the `[alarmIDString: Date.timeIntervalSince1970]`
    /// dictionary. Stored as `[String: Double]` since UserDefaults doesn't
    /// preserve `Date` inside dictionaries losslessly.
    static let userDefaultsKey = "com.cgibson.affirmationalarm.missedAlarm.lastSuccessfulFires"

    /// Minimum gap between a scheduled fire and "now" before we'll flag
    /// it. Keeps us from firing false positives right at fire time while
    /// `handleFire` is still running.
    private static let settlingSeconds: TimeInterval = 5 * 60

    // MARK: - Persistence

    /// Record that `alarmID` completed successfully at `date`. Called from
    /// `AlarmKitScheduler.handleFire` after a successful Stop (and after
    /// a Snooze, since snoozing is also an explicit "I heard it" signal).
    static func recordSuccess(alarmID: UUID, date: Date = Date()) {
        var dict = rawDict()
        dict[alarmID.uuidString] = date.timeIntervalSince1970
        UserDefaults.standard.set(dict, forKey: userDefaultsKey)
    }

    /// Read the last-successful-fire timestamp for a specific alarm. Used
    /// by the diagnostics view.
    static func lastSuccess(for alarmID: UUID) -> Date? {
        guard let ts = rawDict()[alarmID.uuidString] else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    /// Full map (for Diagnostics display).
    static func allLastSuccesses() -> [UUID: Date] {
        rawDict().reduce(into: [UUID: Date]()) { acc, pair in
            if let id = UUID(uuidString: pair.key) {
                acc[id] = Date(timeIntervalSince1970: pair.value)
            }
        }
    }

    private static func rawDict() -> [String: Double] {
        UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: Double] ?? [:]
    }

    // MARK: - Detection

    /// Return enabled alarms whose most recent expected fire (within the
    /// last 2 days) is more recent than their last recorded success.
    ///
    /// Ignores alarms with no success history — first-time users wouldn't
    /// learn anything actionable from the banner.
    static func detect(alarms: [Alarm]) -> [Alarm] {
        let successes = rawDict()
        let now = Date()
        var missed: [Alarm] = []

        for alarm in alarms where alarm.isEnabled {
            guard let past = alarm.mostRecentPastFire(withinDays: 2) else { continue }
            // Skip fires that haven't "settled" — could be firing right now.
            guard now.timeIntervalSince(past) > settlingSeconds else { continue }

            guard let lastTs = successes[alarm.id.uuidString] else {
                // No success record: don't cry wolf before first success.
                continue
            }
            let lastSuccess = Date(timeIntervalSince1970: lastTs)
            if lastSuccess >= past { continue }

            missed.append(alarm)
        }
        return missed
    }
}
