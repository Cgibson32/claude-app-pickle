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
///   AlarmKit cuts the main audio, the intent plays `morning-<alarmID>.mp3`
///   + `closing-<alarmID>.mp3` via `AlarmAudioPlayer`. The app does not open.
/// - **Snooze** → `SnoozeMorningIntent` runs with `openAppWhenRun = false`.
///   The current ring is cancelled and a new one-off follow-up alarm is
///   scheduled 10 minutes from now via `scheduleSnoozeFollowUp(...)` below.
@MainActor @Observable
class AlarmKitScheduler {
    typealias ScheduleConfiguration = AlarmManager.AlarmConfiguration<AffirmationAlarmMetadata>

    static let shared = AlarmKitScheduler()

    /// Mirrors the old `AlarmSchedulingService.permissionDenied`. `AlarmListView`
    /// observes this to show its banner and deep-link to Settings.
    var permissionDenied = false

    /// Set to `true` while the morning affirmation sequence is actively
    /// playing through the auto-play observer. `SleepModeView` observes
    /// this to show a "Playing your affirmations..." state.
    var isPlayingMorningAudio = false

    private let manager = AlarmManager.shared

    /// Alarm IDs we've detected as `.alerting` and are handling (or have
    /// handled). Prevents duplicate auto-play when `alarmUpdates` emits
    /// the same `.alerting` state multiple times.
    private var currentlyAlerting: Set<UUID> = []
    private var alarmObserverTask: Task<Void, Never>?

    private init() {
        observeAuthorizationUpdates()
        observeAlarmFireUpdates()
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

    // MARK: - Auto-play observer
    //
    // Observes `AlarmManager.alarmUpdates` — an async sequence that emits
    // the full `[Alarm]` array whenever any alarm's state changes. When an
    // alarm transitions to `.alerting`, we immediately cancel the system
    // alarm (stopping `.default`) and play the pre-rendered morning
    // affirmation audio via `AlarmAudioPlayer`.
    //
    // IMPORTANT: This observer only fires while the app is in the foreground.
    // Sleep Mode (`SleepModeView`) keeps the app foregrounded overnight with
    // `isIdleTimerDisabled = true` so the observer stays alive. If the user
    // didn't enter Sleep Mode, `StopAndPlayClosingIntent` serves as the
    // fallback when they slide Stop. Both paths route through
    // `AlarmAudioPlayer` which deduplicates, so there's never double audio.

    private func observeAlarmFireUpdates() {
        alarmObserverTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for await alarms in self.manager.alarmUpdates {
                self.handleAlarmUpdate(alarms)
            }
        }
    }

    private func handleAlarmUpdate(_ alarms: [AlarmKit.Alarm]) {
        let alertingIDs = Set(alarms.filter { $0.state == .alerting }.map(\.id))

        // Clean up IDs that are no longer alerting (user tapped Stop/Snooze).
        currentlyAlerting = currentlyAlerting.intersection(alertingIDs)

        // Start auto-play for newly-alerting alarms.
        for alarm in alarms where alarm.state == .alerting {
            let id = alarm.id
            guard !currentlyAlerting.contains(id) else { continue }
            currentlyAlerting.insert(id)

            Task { @MainActor [weak self] in
                await self?.handleFire(alarmID: id)
            }
        }
    }

    private func handleFire(alarmID: UUID) async {
        // Check that pre-rendered files exist. If missing, let .default
        // keep ringing as a safety net.
        let soundsDir = MorningAudioRenderer.soundsDirectory()
        let morningExists = FileManager.default.fileExists(
            atPath: soundsDir.appendingPathComponent("morning-\(alarmID.uuidString).mp3").path
        )
        guard morningExists else {
            AppLogger.alarm.info("auto-play: no morning file for \(alarmID.uuidString.prefix(8), privacy: .public), letting .default ring")
            return
        }

        // Cancel the alarm immediately — no delay. This stops .default
        // and we take over audio entirely with the affirmation sequence.
        // NOTE: cancel(id:) removes the alarm from the system daemon.
        // For repeating alarms we re-schedule via the reconcile
        // notification posted below.
        try? manager.cancel(id: alarmID)

        // Play the morning affirmation sequence + closing via the shared actor.
        isPlayingMorningAudio = true
        let outcome = await AlarmAudioPlayer.shared.playMorningAndClosing(for: alarmID)
        isPlayingMorningAudio = false
        AppLogger.alarm.info("auto-play: \(alarmID.uuidString.prefix(8), privacy: .public) outcome=\(String(describing: outcome), privacy: .public)")

        currentlyAlerting.remove(alarmID)

        // Tell the app to reconcile — this re-schedules repeating alarms
        // that were removed by cancel(id:) above.
        NotificationCenter.default.post(name: .didCompleteMorningPlayback, object: nil)
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

        let stopIntent = StopAndPlayClosingIntent(alarmID: alarm.id)
        let snoozeIntent = SnoozeMorningIntent(alarmID: alarm.id)

        // Prefer the pre-rendered combined CAF file so the alarm sound
        // IS the personalized affirmation sequence — no user interaction
        // needed. mobiletimerd only supports WAV/AIFF/CAF for .named(),
        // and the filename must be passed WITHOUT extension.
        // Falls back to .default if the CAF hasn't been rendered yet.
        let sound: AlertConfiguration.AlertSound
        if MorningAudioRenderer.hasAlarmCAF(for: alarm) {
            sound = .named(MorningAudioRenderer.alarmCAFStem(for: alarm))
        } else {
            sound = .default
        }

        return ScheduleConfiguration.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: snoozeIntent,
            sound: sound
        )
    }

    // MARK: - Snooze follow-up

    /// Schedule a one-off follow-up alarm 10 minutes from now, called from
    /// `SnoozeMorningIntent.perform()` when the user taps Snooze on the
    /// main alarm. Its presentation has NO secondary button — the user gets
    /// one snooze per ring, then must tap Stop on the follow-up to dismiss.
    ///
    /// The follow-up's stopIntent is `StopAndPlayClosingIntent`, but since
    /// no `morning-<followUpID>.mp3` was rendered for this fresh UUID, the
    /// intent's `AlarmAudioPlayer` returns `.noFiles` and the alarm just
    /// dismisses silently. That's the intended behavior.
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
        let stopIntent = StopAndPlayClosingIntent(alarmID: followUpID)

        // .default because .named() is broken on iOS 26.1 (FB19779004).
        let config = ScheduleConfiguration.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: nil,
            sound: .default
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
