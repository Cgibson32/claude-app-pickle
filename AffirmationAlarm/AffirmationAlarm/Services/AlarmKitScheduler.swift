import ActivityKit
// `@preconcurrency` silences Swift 6 region-based isolation errors for
// AlarmKit's async APIs. `requestAuthorization()` and `schedule(id:_:)`
// are declared nonisolated and take an `AlarmConfiguration` containing
// a `(any LiveActivityIntent)?` existential — not yet `Sendable` in the
// AlarmKit SDK. This `@preconcurrency` import is Apple's sanctioned
// escape hatch until AlarmKit ships proper `sending` annotations.
@preconcurrency import AlarmKit
import AppIntents
import SwiftUI

// MARK: - Metadata

/// Per-alarm metadata attached to every AlarmKit entry. Conformances
/// (Codable/Hashable/Sendable) auto-synthesize because every stored
/// property is itself Codable/Hashable/Sendable.
struct AffirmationAlarmMetadata: AlarmMetadata {
    let alarmID: UUID
    let label: String
}

// MARK: - Scheduler

/// Central coordinator for the app's alarm pipeline. Owns three concerns,
/// each isolated behind a clear internal interface:
///
/// - **Permission** (`requestPermission`, `permissionDenied`): authorization
///   state machine mirroring `AlarmManager.authorizationState` as an
///   observable Swift property.
/// - **Scheduling** (`scheduleAlarm`, `cancelAlarm`, `reconcile`,
///   `scheduleSnoozeFollowUp`): idempotent CRUD over AlarmKit entries.
/// - **Auto-play routing** (private): observes `alarmUpdates` and, when
///   an alarm fires while the app is foregrounded, cancels the system
///   alert and hands control to `AlarmAudioPlayer`.
///
/// ## Why three playback paths (defense in depth)
///
/// On iOS 26.3.1, two framework bugs can silence an alarm:
///
/// - **FB19779004** (filed Aug 2025, unverified as of Apr 2026): `.named()`
///   with a file in `Library/Sounds` silently falls back to `.default`.
/// - **26.3.1 silent-alarm regression** (user reports, Apr 2026): some
///   alarms ring silently with no audio and no haptics.
///
/// Neither bug prevents AlarmKit from emitting a `.alerting` state update,
/// so we detect the fire event regardless and take over audio ourselves:
///
/// 1. **`.named(CAF)` primary** — if iOS 26.3.1 fixed FB19779004, the
///    system daemon plays `alarm-<id>.caf` as the alarm sound and the
///    user wakes hands-free to their personalized Nova affirmations.
/// 2. **Foreground observer** — if the app is foregrounded (Sleep Mode
///    bedside clock, `isIdleTimerDisabled = true`), `alarmUpdates`
///    catches `.alerting` and `AlarmAudioPlayer` plays the rendered
///    MP3 sequence via AVAudioPlayer. Works even if `.default` is silent.
/// 3. **Stop-slide intent** — if the app is backgrounded and the observer
///    can't fire, the user's slide-to-stop triggers
///    `StopAndPlayClosingIntent` which plays the same MP3 sequence.
///
/// Any single path succeeding delivers the user's affirmations.
@MainActor
@Observable
final class AlarmKitScheduler {

    // MARK: - Singleton

    static let shared = AlarmKitScheduler()

    // MARK: - Observable state

    /// `true` when the user has explicitly denied AlarmKit authorization.
    /// `AlarmListView` observes this to show a deep-link banner.
    var permissionDenied: Bool = false

    /// `true` while the morning affirmation sequence is playing via the
    /// foreground observer. `SleepModeView` observes this to render a
    /// "Playing your affirmations..." state.
    var isPlayingMorningAudio: Bool = false

    // MARK: - Private state

    private let manager = AlarmManager.shared

    /// Alarm IDs currently being auto-played (or recently auto-played).
    /// Prevents the observer from re-firing on duplicate `.alerting`
    /// updates for the same alarm.
    private var activeFireHandling: Set<UUID> = []

    /// Background task for the `authorizationUpdates` stream. Stored so
    /// we could cancel it for teardown (we don't today, but the lifecycle
    /// is explicit rather than fire-and-forget).
    private var authorizationObserverTask: Task<Void, Never>?

    /// Background task for the `alarmUpdates` stream.
    private var fireObserverTask: Task<Void, Never>?

    // MARK: - Diagnostics state (for DiagnosticsView)

    /// Timestamp of the most recent `alarmUpdates` emission. `nil` if
    /// the observer has never received an event this session.
    private(set) var lastUpdateReceived: Date?

    /// The most recent alarm ID observed transitioning to `.alerting`,
    /// plus when. `nil` if no alarm has fired this session.
    private(set) var lastAlertingAlarm: AlertingEvent?

    /// The most recent `handleFire` invocation's outcome string + when.
    /// `nil` if no alarm has completed a fire handler this session.
    private(set) var lastHandleFireOutcome: FireOutcome?

    /// The alarm ID + timestamp of the most recent `.alerting` emission.
    struct AlertingEvent: Sendable {
        let alarmID: UUID
        let date: Date
    }

    /// The outcome string (from `AlarmAudioPlayer.PlaybackOutcome`) and
    /// timestamp of the most recent `handleFire` completion.
    struct FireOutcome: Sendable {
        let outcome: String
        let date: Date
    }

    /// Snapshot of state currently tracked by the scheduler — read by
    /// the Diagnostics view.
    struct DiagnosticsSnapshot: Sendable {
        let permissionDenied: Bool
        let isPlayingMorningAudio: Bool
        let activeFireHandlingCount: Int
        let lastUpdateReceived: Date?
        let lastAlertingAlarm: AlertingEvent?
        let lastHandleFireOutcome: FireOutcome?

        /// Placeholder for the Diagnostics view's `@State` default.
        static let empty = DiagnosticsSnapshot(
            permissionDenied: false,
            isPlayingMorningAudio: false,
            activeFireHandlingCount: 0,
            lastUpdateReceived: nil,
            lastAlertingAlarm: nil,
            lastHandleFireOutcome: nil
        )
    }

    func diagnosticsSnapshot() -> DiagnosticsSnapshot {
        DiagnosticsSnapshot(
            permissionDenied: permissionDenied,
            isPlayingMorningAudio: isPlayingMorningAudio,
            activeFireHandlingCount: activeFireHandling.count,
            lastUpdateReceived: lastUpdateReceived,
            lastAlertingAlarm: lastAlertingAlarm,
            lastHandleFireOutcome: lastHandleFireOutcome
        )
    }

    // MARK: - Lifecycle

    private init() {
        startObserving()
    }

    private func startObserving() {
        authorizationObserverTask = Task { [weak self] in
            guard let self else { return }
            for await _ in self.manager.authorizationUpdates {
                await self.refreshPermissionStatus()
            }
        }

        fireObserverTask = Task { [weak self] in
            guard let self else { return }
            for await alarms in self.manager.alarmUpdates {
                self.route(alarms: alarms)
            }
        }
    }

    // MARK: - Permission

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let state = try await manager.requestAuthorization()
            let granted = (state == .authorized)
            permissionDenied = !granted
            return granted
        } catch {
            AppLogger.alarm.error("requestAuthorization failed: \(error.localizedDescription, privacy: .public)")
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

    // MARK: - Scheduling

    /// Schedule (or reschedule) the given alarm. Idempotent: any existing
    /// AlarmKit entry with the same id is cancelled before the new entry
    /// is installed.
    ///
    /// If authorization is `.notDetermined`, we request it first. If the
    /// user denies, we set `permissionDenied = true` and return without
    /// scheduling.
    func scheduleAlarm(_ alarm: Alarm) {
        Task { [weak self] in
            guard let self else { return }
            await self.performSchedule(alarm)
        }
    }

    private func performSchedule(_ alarm: Alarm) async {
        try? manager.cancel(id: alarm.id)
        guard alarm.isEnabled else { return }

        if manager.authorizationState == .notDetermined {
            _ = await requestPermission()
        }

        switch manager.authorizationState {
        case .authorized:
            permissionDenied = false
        case .denied:
            permissionDenied = true
            return
        case .notDetermined:
            return
        @unknown default:
            return
        }

        // Guarantee keep-alive is active BEFORE handing the alarm to the
        // system daemon. If the observer Task has no audio session when
        // it starts awaiting `alarmUpdates`, iOS can suspend the process
        // before the first `.alerting` event is delivered.
        BackgroundKeepAlive.shared.start()

        do {
            let configuration = makeConfiguration(for: alarm)
            _ = try await manager.schedule(id: alarm.id, configuration: configuration)
            AppLogger.alarm.info("scheduled alarm \(alarm.id, privacy: .public)")
            DiagnosticsLog.shared.log("scheduler", "scheduled \(alarm.id.uuidString.prefix(8)) sound=\(alarm.soundName)")
        } catch {
            AppLogger.alarm.error("schedule failed for \(alarm.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            DiagnosticsLog.shared.log("scheduler", "schedule failed: \(error.localizedDescription)")
        }
    }

    /// Cancel an alarm. Safe to call even if the alarm isn't currently
    /// scheduled — the underlying `cancel(id:)` errors are ignored.
    ///
    /// We use `cancel` rather than `stop` because `stop` does not reliably
    /// delete one-shot alarms on iOS 26 (documented in the ItsukiAlarm
    /// sample). `cancel` removes the entry from the system daemon
    /// unconditionally.
    func cancelAlarm(_ alarm: Alarm) {
        try? manager.cancel(id: alarm.id)
    }

    /// Cross-reference SwiftData rows with the live AlarmKit registry and
    /// heal any drift on launch.
    ///
    /// - One-shot rows whose AlarmKit entry has disappeared already fired,
    ///   so we flip `isEnabled = false`.
    /// - Repeating rows missing from AlarmKit (e.g. after an app update
    ///   that cleared state) get re-scheduled.
    /// - Rows still live in AlarmKit are left alone.
    func reconcile(alarms: [Alarm]) {
        let enabled = alarms.filter(\.isEnabled)
        guard !enabled.isEmpty else { return }

        let live = (try? manager.alarms) ?? []
        let liveIDs = Set(live.map(\.id))

        for alarm in enabled {
            if liveIDs.contains(alarm.id) { continue }

            if alarm.repeatDays.isEmpty {
                alarm.isEnabled = false
            } else {
                scheduleAlarm(alarm)
            }
        }
    }

    // MARK: - Snooze follow-up

    /// Schedule a one-shot follow-up 10 minutes from now, invoked by
    /// `SnoozeMorningIntent` when the user taps Snooze.
    ///
    /// The follow-up has no snooze button (one snooze per ring) and uses
    /// `.default` for its sound because we don't render audio for fresh
    /// follow-up UUIDs. If the user slides Stop on the follow-up, the
    /// Stop intent's `AlarmAudioPlayer` returns `.noFiles` and dismisses
    /// silently — which is the intended behavior.
    func scheduleSnoozeFollowUp(originalAlarmID: UUID) {
        let followUpID = UUID()
        let fireDate = Date().addingTimeInterval(10 * 60)

        let presentation = AlarmPresentation(
            alert: AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: "Time to get up")
            )
        )
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: AffirmationAlarmMetadata(alarmID: followUpID, label: "Snooze follow-up"),
            tintColor: Color.orange
        )

        let configuration = ScheduleConfiguration.alarm(
            schedule: AlarmKit.Alarm.Schedule.fixed(fireDate),
            attributes: attributes,
            stopIntent: StopAndPlayClosingIntent(alarmID: followUpID),
            secondaryIntent: nil,
            sound: .default
        )

        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.manager.schedule(id: followUpID, configuration: configuration)
                AppLogger.alarm.info("scheduled snooze follow-up \(followUpID, privacy: .public)")
            } catch {
                AppLogger.alarm.error("snooze follow-up schedule failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - Auto-play routing

    /// Called from the `alarmUpdates` stream for every state transition.
    /// Emits a `handleFire` task for each newly-alerting alarm and prunes
    /// our in-memory tracking set once the alarm leaves `.alerting`.
    private func route(alarms: [AlarmKit.Alarm]) {
        lastUpdateReceived = Date()

        let alerting = Set(alarms.filter { $0.state == .alerting }.map(\.id))
        activeFireHandling.formIntersection(alerting)

        let newlyAlerting = alerting.subtracting(activeFireHandling)
        for alarmID in newlyAlerting {
            activeFireHandling.insert(alarmID)
            lastAlertingAlarm = AlertingEvent(alarmID: alarmID, date: Date())
            DiagnosticsLog.shared.log("observer", "alerting \(alarmID.uuidString.prefix(8))")
            Task { [weak self] in
                await self?.handleFire(alarmID: alarmID)
            }
        }
    }

    /// Cancel the system alert (stopping whatever `.default`/`.named()`
    /// sound was playing — or not playing, on 26.3.1's silent-alarm bug)
    /// and play the pre-rendered MP3 sequence via `AlarmAudioPlayer`.
    ///
    /// After playback, post `.didCompleteMorningPlayback` so the app can
    /// re-schedule any repeating alarm we just cancelled.
    private func handleFire(alarmID: UUID) async {
        defer { activeFireHandling.remove(alarmID) }

        DiagnosticsLog.shared.log("observer", "handleFire start \(alarmID.uuidString.prefix(8))")

        let soundsDir = MorningAudioRenderer.soundsDirectory()
        let morningURL = soundsDir.appendingPathComponent("morning-\(alarmID.uuidString).mp3")
        guard FileManager.default.fileExists(atPath: morningURL.path) else {
            AppLogger.alarm.info("observer: no morning render for \(alarmID.uuidString.prefix(8), privacy: .public); letting system sound continue")
            lastHandleFireOutcome = FireOutcome(outcome: "noMorningRender", date: Date())
            DiagnosticsLog.shared.log("observer", "no morning render — leaving system sound")
            return
        }

        try? manager.cancel(id: alarmID)

        isPlayingMorningAudio = true
        let outcome = await AlarmAudioPlayer.shared.playMorningAndClosing(for: alarmID)
        isPlayingMorningAudio = false

        AppLogger.alarm.info("observer: \(alarmID.uuidString.prefix(8), privacy: .public) outcome=\(String(describing: outcome), privacy: .public)")
        lastHandleFireOutcome = FireOutcome(outcome: String(describing: outcome), date: Date())
        DiagnosticsLog.shared.log("observer", "handleFire outcome=\(outcome)")

        // AlarmAudioPlayer deactivates the audio session when it finishes.
        // For repeating alarms (and any one-shot followed by a reschedule),
        // we need the keep-alive session live again so tomorrow's observer
        // is still running. Restart immediately rather than waiting for the
        // reconcile-via-notification detour to do it — minimizes the window
        // where iOS could suspend the process.
        BackgroundKeepAlive.shared.start()

        NotificationCenter.default.post(name: .didCompleteMorningPlayback, object: nil)
    }

    // MARK: - Configuration builder

    private typealias ScheduleConfiguration = AlarmManager.AlarmConfiguration<AffirmationAlarmMetadata>

    private func makeConfiguration(for alarm: Alarm) -> ScheduleConfiguration {
        let title = LocalizedStringResource(
            stringLiteral: alarm.label.isEmpty ? "Morning Affirmations" : alarm.label
        )

        // AlarmKit provides the Stop button automatically in iOS 26.
        // We customize the Snooze (secondary) button only.
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

        // Fully qualify `AlarmKit.Alarm` — our SwiftData model is also
        // named `Alarm` and shadows the framework type at this scope.
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

        return ScheduleConfiguration.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: StopAndPlayClosingIntent(alarmID: alarm.id),
            secondaryIntent: SnoozeMorningIntent(alarmID: alarm.id),
            sound: resolveSound(for: alarm)
        )
    }

    /// Pick the AlarmKit sound for this alarm.
    ///
    /// We pass `.named(alarm.soundName)` pointing to a CAF in the **app
    /// bundle** (e.g. `alarm_gentle.caf`, `alarm_sunrise.caf`). Research
    /// (Apr 2026) confirms bundle-resident audio is the one `.named()`
    /// location that reliably works under the open FB19779004 bug —
    /// `Library/Sounds` silently falls back to `.default`.
    ///
    /// Per-user personalized affirmations are layered on top by the
    /// `alarmUpdates` observer and the Stop-slide intent, which play
    /// `morning-<id>.mp3` and `closing-<id>.mp3` via `AlarmAudioPlayer`
    /// after the system daemon has started the bundled alarm tone.
    private func resolveSound(for alarm: Alarm) -> AlertConfiguration.AlertSound {
        let stem = alarm.soundName
        AppLogger.alarm.info("sound: .named(\(stem, privacy: .public)) [bundle] for \(alarm.id.uuidString.prefix(8), privacy: .public)")
        return .named(stem)
    }

    // MARK: - Weekday mapping

    /// Map Apple `Calendar.weekday` (1 = Sunday ... 7 = Saturday) to
    /// `Locale.Weekday`. Returns `nil` for out-of-range input so the
    /// caller can filter garbage values with `compactMap`.
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
