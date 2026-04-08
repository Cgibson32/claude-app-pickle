import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI

// MARK: - Metadata

/// Custom metadata payload attached to every AlarmKit alarm we schedule.
/// `AlarmMetadata` requires `Sendable`; making the struct `nonisolated`
/// keeps it free of actor isolation so AlarmKit can deserialize it on any
/// thread when the alarm fires.
nonisolated struct AffirmationAlarmMetadata: AlarmMetadata {
    let alarmID: UUID
    let label: String

    init(alarmID: UUID, label: String) {
        self.alarmID = alarmID
        self.label = label
    }
}

// MARK: - Scheduler

/// Thin wrapper around `AlarmManager.shared` that mirrors the public shape of
/// the old `AlarmSchedulingService` so call sites (`AlarmListView`,
/// `AlarmDetailView`, `OnboardingViewModel`) don't need structural changes.
///
/// Unlike the `UNUserNotificationCenter` path this replaces, AlarmKit:
/// - rings through silent mode, Focus, and DND
/// - has no 30-second audio cap (we play the full sequence live when the app
///   comes to the foreground via `StartMorningRitualIntent`)
/// - persists alarms in the system rather than in our notification queue, so
///   we only ever have one configuration per `Alarm` row regardless of
///   weekday repetition
@MainActor @Observable
class AlarmKitScheduler {
    typealias ScheduleConfiguration = AlarmManager.AlarmConfiguration<AffirmationAlarmMetadata>

    static let shared = AlarmKitScheduler()

    /// Mirrors the old `AlarmSchedulingService.permissionDenied`. `AlarmListView`
    /// observes this to show its banner and deep-link to Settings.
    var permissionDenied = false

    private let manager = AlarmManager.shared

    private init() {
        observeAuthorizationUpdates()
    }

    // MARK: - Permission

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let state = try await manager.requestAuthorization()
            let authorized = (state == .authorized)
            permissionDenied = !authorized
            return authorized
        } catch {
            permissionDenied = true
            return false
        }
    }

    func refreshPermissionStatus() async {
        switch manager.authorizationState {
        case .authorized:
            permissionDenied = false
        case .denied:
            permissionDenied = true
        case .notDetermined:
            permissionDenied = false
        @unknown default:
            permissionDenied = false
        }
    }

    private func observeAuthorizationUpdates() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            for await _ in self.manager.authorizationUpdates {
                await self.refreshPermissionStatus()
            }
        }
    }

    // MARK: - Scheduling

    /// Schedule (or reschedule) a single `Alarm` row. Idempotent: always
    /// cancels any existing AlarmKit entry with the same id before scheduling.
    func scheduleAlarm(_ alarm: Alarm) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            // Always cancel the existing entry first so edits replace cleanly.
            try? self.manager.cancel(id: alarm.id)

            guard alarm.isEnabled else { return }

            // Request authorization if we haven't asked yet.
            if self.manager.authorizationState == .notDetermined {
                _ = await self.requestPermission()
            }

            switch self.manager.authorizationState {
            case .authorized:
                self.permissionDenied = false
            case .denied:
                self.permissionDenied = true
                return
            case .notDetermined:
                return
            @unknown default:
                return
            }

            do {
                let configuration = self.makeConfiguration(for: alarm)
                _ = try await self.manager.schedule(id: alarm.id, configuration: configuration)
                alarm.notificationIdentifiers = [alarm.id.uuidString]
            } catch {
                #if DEBUG
                print("[AlarmKitScheduler] schedule failed for \(alarm.id): \(error)")
                #endif
            }
        }
    }

    /// Stop / cancel an alarm. Safe to call on alarms that are not currently
    /// scheduled — errors from `AlarmManager.cancel` are swallowed.
    ///
    /// Uses `cancel` (not `stop`) because the ItsukiAlarm sample notes that
    /// `stop` does not reliably delete one-shot alarms; `cancel` removes the
    /// alarm from the system daemon unconditionally.
    func cancelAlarm(_ alarm: Alarm) {
        let id = alarm.id
        alarm.notificationIdentifiers = []
        // `cancel(id:)` is sync and non-isolated; we can call it directly
        // without spawning a Task.
        try? manager.cancel(id: id)
    }

    /// Cross-reference SwiftData `Alarm` rows with the system's live
    /// AlarmKit alarms and self-heal any drift on launch. This replaces the
    /// old `rescheduleAll(_:)` / `rehydrateAlarms()` loop.
    ///
    /// - One-shot rows (`repeatDays.isEmpty`) whose AlarmKit entry is gone
    ///   have already fired, so we flip `isEnabled = false` to match the
    ///   pre-migration "auto-disable after fire" contract.
    /// - Repeating rows simply get re-scheduled if their AlarmKit entry is
    ///   missing (first-run rehydration after an app update).
    /// - Enabled rows that ARE present in AlarmKit are left alone.
    func reconcile(alarms: [Alarm]) {
        let enabled = alarms.filter { $0.isEnabled }
        guard !enabled.isEmpty else { return }

        // `manager.alarms` is a sync `throws` property; wrap in try? and
        // default to [] so a first-launch auth-not-yet-granted error is
        // silently ignored.
        let live = (try? manager.alarms) ?? []
        let liveIDs = Set(live.map(\.id))

        for alarm in enabled {
            if liveIDs.contains(alarm.id) {
                continue  // Already scheduled in the system.
            }

            if alarm.repeatDays.isEmpty {
                // One-shot that's no longer present = already fired.
                alarm.isEnabled = false
                alarm.notificationIdentifiers = []
            } else {
                // Repeating alarm missing from the system (e.g. first
                // launch after update) — re-arm it.
                scheduleAlarm(alarm)
            }
        }
    }

    // MARK: - Configuration builder

    private func makeConfiguration(for alarm: Alarm) -> ScheduleConfiguration {
        let title = LocalizedStringResource(
            stringLiteral: alarm.label.isEmpty ? "Morning Affirmations" : alarm.label
        )

        // The iOS 26 release of `AlarmPresentation.Alert` no longer accepts
        // a `stopButton:` parameter — the system provides a default stop
        // button automatically. Custom behavior on tap is wired up via the
        // `stopIntent:` on the `AlarmConfiguration` below.
        let alertPresentation = AlarmPresentation.Alert(title: title)

        let presentation = AlarmPresentation(alert: alertPresentation)

        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: AffirmationAlarmMetadata(alarmID: alarm.id, label: alarm.label),
            tintColor: Color.orange
        )

        // Fully qualify AlarmKit's `Alarm` type — our SwiftData model is
        // also named `Alarm` and shadows the framework type at this scope.
        let time = AlarmKit.Alarm.Schedule.Relative.Time(hour: alarm.hour, minute: alarm.minute)

        let recurrence: AlarmKit.Alarm.Schedule.Relative.Recurrence
        if alarm.repeatDays.isEmpty {
            recurrence = .never
        } else {
            let weekdays = alarm.repeatDays.compactMap(Self.weekday(fromAppleWeekday:))
            recurrence = .weekly(weekdays)
        }

        let schedule = AlarmKit.Alarm.Schedule.relative(
            AlarmKit.Alarm.Schedule.Relative(time: time, repeats: recurrence)
        )

        // The AlarmKit tap-to-stop button runs this App Intent. It has
        // `openAppWhenRun = true`, so tapping it both stops the alarm AND
        // launches the app into the foreground; the intent then posts
        // `.didTapAlarmNotification`, which `RootView` listens for to
        // present the full affirmation sequence.
        let stopIntent = StartMorningRitualIntent(alarmID: alarm.id)

        // Use the static `.alarm(...)` convenience initializer for
        // schedule-only (non-countdown) alarms. Equivalent to passing
        // `countdownDuration: nil` to the full initializer.
        //
        // Sound note: the iOS 26 beta had a bug where `.default` played no
        // sound; `.named("alarm_gentle.caf")` uses the bundled file we
        // already ship and should play reliably. If the sound fails to play
        // post-migration, fall back to `.named("")` which the sample reports
        // as triggering the system default.
        return ScheduleConfiguration.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: nil,
            sound: .named("\(alarm.soundName).caf")
        )
    }

    /// Map Apple `Calendar.weekday` (1 = Sunday ... 7 = Saturday) to
    /// AlarmKit's `Locale.Weekday`. Returns `nil` for out-of-range input.
    private static func weekday(fromAppleWeekday apple: Int) -> Locale.Weekday? {
        switch apple {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return nil
        }
    }
}
