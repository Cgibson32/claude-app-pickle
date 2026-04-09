import ActivityKit
// `@preconcurrency` silences Swift 6's region-based isolation errors for
// AlarmKit's async APIs (`requestAuthorization()`, `schedule(id:configuration:)`).
// Those methods are declared nonisolated and take an `AlarmConfiguration`
// that contains `(any LiveActivityIntent)?` — a non-Sendable protocol
// existential — so the strict Swift 6 region check flags the main-actor
// isolated `self.manager` and `configuration` values as "sending ... risks
// causing data races" when they cross the await boundary. AlarmKit wasn't
// annotated for Swift 6 strict concurrency; `@preconcurrency import` is
// Apple's sanctioned escape hatch for exactly this case until the framework
// ships proper `sending` / `Sendable` annotations in a future SDK.
@preconcurrency import AlarmKit
import AppIntents
import SwiftUI

// MARK: - Metadata

/// Custom metadata payload attached to every AlarmKit alarm we schedule.
/// `AlarmMetadata` inherits `Decodable`, `Encodable`, `Hashable`, and
/// `Sendable`; all four conformances auto-synthesize here because `UUID`
/// and `String` are themselves Codable/Hashable/Sendable.
struct AffirmationAlarmMetadata: AlarmMetadata {
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
/// - plays pre-rendered personalized audio (greeting + affirmations) as the
///   alarm sound itself, via `MorningAudioRenderer`
/// - persists alarms in the system rather than in our notification queue, so
///   we only ever have one configuration per `Alarm` row regardless of
///   weekday repetition
///
/// Each scheduled alarm has TWO buttons on the ringing UI:
///
/// - **Stop** → `StopAndPlayClosingIntent` runs with `openAppWhenRun = false`.
///   AlarmKit cuts the main audio, the intent loads `closing-<alarmID>.wav`
///   and plays it via AVAudioPlayer. The app does not open.
/// - **Snooze** → `SnoozeMorningIntent` runs with `openAppWhenRun = false`.
///   The current ring is cancelled and a new one-off follow-up alarm is
///   scheduled 10 minutes from now via `scheduleSnoozeFollowUp(...)` below,
///   using the pre-rendered `snooze-<originalAlarmID>.wav` as its sound.
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
                AppLogger.alarm.info("scheduled alarm \(alarm.id, privacy: .public)")
            } catch {
                AppLogger.alarm.error("schedule failed for \(alarm.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
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

        // The iOS 26 release of `AlarmPresentation.Alert` dropped the
        // `stopButton:` parameter — AlarmKit provides the stop button
        // automatically and we wire its tap behavior via `stopIntent:` on
        // the `AlarmConfiguration` below. The secondary (snooze) button
        // IS customizable via `secondaryButton:` + `.custom` behavior.
        let snoozeButton = AlarmButton(
            text: "Snooze",
            textColor: .white,
            systemImageName: "zzz"
        )

        let alertPresentation = AlarmPresentation.Alert(
            title: title,
            secondaryButton: snoozeButton,
            secondaryButtonBehavior: .custom
        )

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

        // Stop button → plays the pre-rendered `closing-<alarmID>.wav` via
        // AVAudioPlayer, `openAppWhenRun = false`. App does not launch.
        let stopIntent = StopAndPlayClosingIntent(alarmID: alarm.id)

        // Snooze button → cancels this ring and schedules a 10-minute
        // follow-up alarm with `snooze-<alarmID>.wav` as its sound.
        // `openAppWhenRun = false`. App does not launch.
        let snoozeIntent = SnoozeMorningIntent(alarmID: alarm.id)

        // Prefer the pre-rendered personalized audio if `MorningAudioRenderer`
        // has already written a file for this alarm into `Library/Sounds/`.
        // If no rendered file exists yet (first launch, TTS failure, etc.)
        // fall back to the bundled tone the user picked in onboarding so
        // the alarm still rings reliably.
        let soundName: String
        if let rendered = MorningAudioRenderer.existingRenderedFilename(for: alarm) {
            soundName = rendered
        } else {
            soundName = "\(alarm.soundName).caf"
        }

        // Use the static `.alarm(...)` convenience initializer for
        // schedule-only (non-countdown) alarms. Equivalent to passing
        // `countdownDuration: nil` to the full initializer.
        return ScheduleConfiguration.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: snoozeIntent,
            sound: .named(soundName)
        )
    }

    // MARK: - Snooze follow-up

    /// Schedule a one-off follow-up alarm 10 minutes from now, called from
    /// `SnoozeMorningIntent.perform()` when the user taps Snooze on the
    /// main alarm.
    ///
    /// The follow-up uses `snooze-<originalAlarmID>.wav` (pre-rendered by
    /// `MorningAudioRenderer`: selected alarm tone beeping briefly, then
    /// *"Time to get up, [Name]. Let's have a great day."*) as its sound.
    /// Its presentation has NO secondary button — the user gets one snooze
    /// per ring, then must tap Stop on the follow-up to dismiss.
    ///
    /// The follow-up's stopIntent is still `StopAndPlayClosingIntent`, but
    /// since no `closing-<followUpID>.wav` was rendered for this fresh
    /// UUID, the intent falls through to its no-file no-op and the alarm
    /// just dismisses silently. That's the intended behavior — we already
    /// played the closing on the original alarm's stop (if they'd hit stop
    /// instead of snooze), and the snooze follow-up's job is to get them
    /// up, not to wind down again.
    func scheduleSnoozeFollowUp(originalAlarmID: UUID) {
        let followUpID = UUID()
        let fireDate = Date().addingTimeInterval(10 * 60)

        let title = LocalizedStringResource(stringLiteral: "Time to get up")
        let presentation = AlarmPresentation(
            alert: AlarmPresentation.Alert(title: title)
        )
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: AffirmationAlarmMetadata(alarmID: followUpID, label: "Snooze follow-up"),
            tintColor: Color.orange
        )

        let schedule = AlarmKit.Alarm.Schedule.fixed(fireDate)

        // Use the pre-rendered snooze audio keyed to the ORIGINAL alarm ID
        // — one snooze file per source alarm, regenerated daily alongside
        // the main + closing files. `.caf` (not `.wav`) because AlarmKit
        // on iOS 26.1 silently drops `.named(*.wav)` sounds; see the
        // long comment in `MorningAudioRenderer.writeAsCAF`.
        let soundFile = "snooze-\(originalAlarmID.uuidString).caf"
        let snoozeURL = FileManager.default
            .urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sounds/\(soundFile)")
        let sound: AlertConfiguration.AlertSound = FileManager.default.fileExists(atPath: snoozeURL.path)
            ? .named(soundFile)
            : .default

        let stopIntent = StopAndPlayClosingIntent(alarmID: followUpID)

        let config = ScheduleConfiguration.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: nil,
            sound: sound
        )

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.manager.schedule(id: followUpID, configuration: config)
                AppLogger.alarm.info("scheduled snooze follow-up \(followUpID, privacy: .public)")
            } catch {
                AppLogger.alarm.error("snooze follow-up schedule failed: \(error.localizedDescription, privacy: .public)")
            }
        }
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
