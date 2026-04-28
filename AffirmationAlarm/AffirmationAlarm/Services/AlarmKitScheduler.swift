import ActivityKit
// `@preconcurrency` silences Swift 6 region-based isolation errors for
// AlarmKit's async APIs. `requestAuthorization()` and `schedule(id:_:)`
// are declared nonisolated and take an `AlarmConfiguration` containing
// a `(any LiveActivityIntent)?` existential — not yet `Sendable` in the
// AlarmKit SDK. This `@preconcurrency` import is Apple's sanctioned
// escape hatch until AlarmKit ships proper `sending` annotations.
@preconcurrency import AlarmKit
import AppIntents
import AVFoundation
import SwiftData
import SwiftUI
import UserNotifications

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
/// ## Two-layer alarm audio
///
/// The alarm **sound** and the affirmation **sequence** are separate
/// audio because iOS 26.3.1's `.named()` cannot play runtime-generated
/// audio reliably (FB19779004, unresolved as of Apr 2026 — reading a
/// CAF from `Library/Sounds` silently falls back to `.default`). Only
/// bundle-resident CAFs work.
///
/// Layer 1 — the alarm **sound** (briefly, from the system daemon):
///   `.named(alarm.soundName)` points to a bundled CAF the user picked
///   in the sound picker (`alarm_gentle`, `alarm_sunrise`, etc.). Plays
///   for ~1 second until the observer cancels.
///
/// Layer 2 — the personalized **sequence** (from the app's own
/// AVAudioPlayer, via two entry points that share `AlarmAudioPlayer`):
///
/// a. `alarmUpdates` observer (primary, hands-free path): the app
///    process is alive overnight via `BackgroundKeepAlive`'s silent
///    audio session. When AlarmKit emits `.alerting`, `handleFire`
///    cancels the alarm, waits 400ms for the system to release its
///    audio session, then plays morning + closing MP3s. Works with
///    the phone locked and the screen off.
///
/// b. `StopAndPlayClosingIntent` (fallback): if the observer didn't
///    play the full sequence — e.g. the process was killed from the
///    app switcher — sliding Stop runs the intent, which foregrounds
///    the app (`openAppWhenRun = true`). `checkPendingMorningPlayback`
///    then plays the same MP3s from the foreground where audio
///    session activation is never contested.
///
/// `AlarmAudioPlayer` is an actor so both entry points serialize — the
/// user hears the sequence exactly once even if both paths execute.
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
    /// foreground observer.
    var isPlayingMorningAudio: Bool = false

    /// Non-nil while the in-app ringing UI is showing. The observer sets
    /// this when an alarm fires while the app is foregrounded, and clears
    /// it when the user presses Stop or Snooze. SwiftUI views observe
    /// this to present the ringing overlay.
    var ringingAlarmID: UUID?

    /// Label for the alarm currently ringing (shown in the ringing UI).
    var ringingAlarmLabel: String = ""

    /// Legacy field kept for telemetry/diagnostics compatibility — always
    /// false since the bedtime mode UI was removed (the alarm fires
    /// reliably without any pre-bed user step).
    var isSleepModeActive: Bool = false

    /// Follow-up UUIDs waiting for audio rendering. Drained by
    /// `RootView.reconcileAlarmsWithSystem` which has the ModelContext
    /// required for generation + TTS.
    private(set) var pendingFollowUpRenders: Set<UUID> = []

    // MARK: - Ringing state machine

    enum RingingAction: Sendable { case stop, snooze }

    /// Continuation for the currently-active ringing stream. `nil` when no
    /// alarm is ringing. Yielding an action (Stop/Snooze/timeout) unblocks
    /// `handleFire`'s `for await` loop.
    ///
    /// We moved off `CheckedContinuation` to `AsyncStream.Continuation` for
    /// one reason: `AsyncStream.Continuation.yield` is idempotent — a second
    /// yield with the same or a different value is a no-op once we've
    /// `finish()`ed. The previous `CheckedContinuation.resume(returning:)`
    /// pattern traps on a double-resume, which is easy to hit if a user
    /// taps Stop while the 5-minute timeout is already resuming. The
    /// AsyncStream shape lets us collapse stop/snooze/timeout into a single
    /// "first yield wins" protocol without defensive nil-checks everywhere.
    private var ringingContinuation: AsyncStream<RingingAction>.Continuation?

    /// Alarm ID → sound name, populated at schedule time. Looked up at
    /// fire time to loop the correct alarm tone in the ringing UI.
    private var alarmSoundNames: [UUID: String] = [:]
    private var alarmLabels: [UUID: String] = [:]

    /// Timestamps of recent eager-render attempts per follow-up UUID.
    /// Prevents re-snooze spam from triggering N Claude + N TTS renders
    /// back-to-back. Cleared after `settlingSeconds` by the Task itself.
    private var lastRenderAttempt: [UUID: Date] = [:]

    /// Minimum seconds between eager-render attempts for the same UUID.
    private let renderDebounceSeconds: TimeInterval = 15

    /// Drain the pending follow-up render set after rendering is complete.
    func clearPendingFollowUpRenders() {
        pendingFollowUpRenders.removeAll()
    }

    /// Called by the ringing UI's Stop button. Yields to `handleFire`'s
    /// for-await loop. Idempotent: subsequent presses are absorbed by the
    /// finished stream.
    func userPressedStop() {
        AlarmTelemetry.eventSync(.stopPressed, alarmID: ringingAlarmID)
        ringingContinuation?.yield(.stop)
        ringingContinuation?.finish()
        Task { await AlarmAudioPlayer.shared.stopPlayback() }
    }

    func userPressedSnooze() {
        AlarmTelemetry.eventSync(.snoozePressed, alarmID: ringingAlarmID)
        ringingContinuation?.yield(.snooze)
        ringingContinuation?.finish()
        Task { await AlarmAudioPlayer.shared.stopPlayback() }
    }

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
        let isSleepModeActive: Bool
        let ringingAlarmID: UUID?
        let ringingAlarmLabel: String
        let activeFireHandlingCount: Int
        let pendingFollowUpRenderCount: Int
        let trackedSoundNameCount: Int
        let lastUpdateReceived: Date?
        let lastAlertingAlarm: AlertingEvent?
        let lastHandleFireOutcome: FireOutcome?

        /// Placeholder for the Diagnostics view's `@State` default.
        static let empty = DiagnosticsSnapshot(
            permissionDenied: false,
            isPlayingMorningAudio: false,
            isSleepModeActive: false,
            ringingAlarmID: nil,
            ringingAlarmLabel: "",
            activeFireHandlingCount: 0,
            pendingFollowUpRenderCount: 0,
            trackedSoundNameCount: 0,
            lastUpdateReceived: nil,
            lastAlertingAlarm: nil,
            lastHandleFireOutcome: nil
        )
    }

    func diagnosticsSnapshot() -> DiagnosticsSnapshot {
        DiagnosticsSnapshot(
            permissionDenied: permissionDenied,
            isPlayingMorningAudio: isPlayingMorningAudio,
            isSleepModeActive: isSleepModeActive,
            ringingAlarmID: ringingAlarmID,
            ringingAlarmLabel: ringingAlarmLabel,
            activeFireHandlingCount: activeFireHandling.count,
            pendingFollowUpRenderCount: pendingFollowUpRenders.count,
            trackedSoundNameCount: alarmSoundNames.count,
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

        try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .criticalAlert])

        BackgroundKeepAlive.shared.start()

        do {
            let configuration = makeConfiguration(for: alarm)
            _ = try await manager.schedule(id: alarm.id, configuration: configuration)
            alarmSoundNames[alarm.id] = alarm.soundName
            alarmLabels[alarm.id] = alarm.label
            AppLogger.alarm.info("scheduled alarm \(alarm.id, privacy: .public)")
            DiagnosticsLog.shared.log("scheduler", "scheduled \(alarm.id.uuidString.prefix(8)) sound=\(alarm.soundName)")
            AlarmTelemetry.eventSync(.scheduled, alarmID: alarm.id, extra: "sound=\(alarm.soundName)")
        } catch {
            AppLogger.alarm.error("schedule failed for \(alarm.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            DiagnosticsLog.shared.log("scheduler", "schedule failed: \(error.localizedDescription)")
            AlarmTelemetry.eventSync(.schedulingFailed, alarmID: alarm.id, extra: "err=\(error.localizedDescription)")
        }

        scheduleBackupNotification(for: alarm)
    }

    /// Belt-and-suspenders: schedule a UNNotification at the same time as
    /// the AlarmKit alarm. If AlarmKit fails for any reason, the user still
    /// gets woken up by the notification. Cancelled in handleFire once the
    /// AlarmKit alarm fires successfully.
    private func scheduleBackupNotification(for alarm: Alarm) {
        guard let fireDate = alarm.nextFireDate else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])

        let content = UNMutableNotificationContent()
        content.title = alarm.label.isEmpty ? "Morning Affirmations" : alarm.label
        content.body = "Your alarm is going off — tap to open."
        content.sound = .defaultCritical
        content.interruptionLevel = .timeSensitive

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        center.add(request)
        DiagnosticsLog.shared.log("scheduler", "backup notification for \(alarm.id.uuidString.prefix(8)) at \(alarm.timeString)")
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
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
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
                if alarm.nextFireDate == nil {
                    alarm.isEnabled = false
                    DiagnosticsLog.shared.log("reconcile", "one-shot \(alarm.id.uuidString.prefix(8)) past due — disabled")
                } else {
                    DiagnosticsLog.shared.log("reconcile", "one-shot \(alarm.id.uuidString.prefix(8)) missing from AlarmKit — rescheduling")
                    scheduleAlarm(alarm)
                }
            } else {
                DiagnosticsLog.shared.log("reconcile", "repeating \(alarm.id.uuidString.prefix(8)) missing from AlarmKit — rescheduling")
                scheduleAlarm(alarm)
            }
        }
    }

    // MARK: - Snooze follow-up

    /// Schedule a one-shot follow-up alarm using the original alarm's
    /// sound and a fresh set of affirmations. Invoked by the in-app
    /// ringing UI's Snooze button and by `SnoozeMorningIntent`.
    ///
    /// The follow-up includes a Snooze button so the user can re-snooze
    /// indefinitely. Audio for the follow-up UUID is rendered during the
    /// 10-minute window via `pendingFollowUpRenders`, which `RootView`
    /// drains on the next reconcile pass.
    func scheduleSnoozeFollowUp(originalAlarmID: UUID) {
        let followUpID = UUID()
        let snoozeSec = Double(AppConstants.snoozeDurationMinutes) * 60
        let fireDate = Date().addingTimeInterval(snoozeSec)
        let soundName = alarmSoundNames[originalAlarmID] ?? "alarm_gentle"

        let snoozeButton = AlarmButton(
            text: "Snooze",
            textColor: .white,
            systemImageName: "zzz"
        )
        let presentation = AlarmPresentation(
            alert: AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: "Time to get up"),
                secondaryButton: snoozeButton,
                secondaryButtonBehavior: .custom
            )
        )
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: AffirmationAlarmMetadata(alarmID: followUpID, label: "Snooze follow-up"),
            tintColor: AppTheme.sunsetOrange
        )

        let configuration = ScheduleConfiguration.alarm(
            schedule: AlarmKit.Alarm.Schedule.fixed(fireDate),
            attributes: attributes,
            stopIntent: StopAndPlayClosingIntent(alarmID: followUpID),
            secondaryIntent: SnoozeMorningIntent(alarmID: followUpID),
            sound: .named(soundName)
        )

        alarmSoundNames[followUpID] = soundName
        alarmLabels[followUpID] = "Snooze follow-up"
        pendingFollowUpRenders.insert(followUpID)

        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.manager.schedule(id: followUpID, configuration: configuration)
                AppLogger.alarm.info("scheduled snooze follow-up \(followUpID, privacy: .public) sound=\(soundName, privacy: .public)")
                DiagnosticsLog.shared.log("scheduler", "snooze follow-up \(followUpID.uuidString.prefix(8)) in \(AppConstants.snoozeDurationMinutes)min")
                AlarmTelemetry.eventSync(
                    .snoozeFollowUpScheduled,
                    alarmID: followUpID,
                    extra: "from=\(originalAlarmID.uuidString.prefix(8)) in=\(AppConstants.snoozeDurationMinutes)min"
                )
            } catch {
                AppLogger.alarm.error("snooze follow-up schedule failed: \(error.localizedDescription, privacy: .public)")
                AlarmTelemetry.eventSync(.snoozeFollowUpFailed, alarmID: followUpID, extra: "err=\(error.localizedDescription)")
            }
        }

        eagerRenderFollowUp(followUpID: followUpID)
    }

    /// Eagerly render affirmations for a snooze follow-up with a retry
    /// budget: up to 3 attempts with 1s/2s/4s exponential backoff and a
    /// 30s per-attempt timeout. On total failure, the UUID stays in
    /// `pendingFollowUpRenders` so `RootView.reconcileAlarmsWithSystem`
    /// retries on the next active-scene pass.
    ///
    /// Debounced: if a render for this UUID was attempted within the last
    /// `renderDebounceSeconds`, the call is silently skipped. Prevents
    /// re-snooze spam from burning Claude + TTS credits.
    private func eagerRenderFollowUp(followUpID: UUID) {
        if let last = lastRenderAttempt[followUpID],
           Date().timeIntervalSince(last) < renderDebounceSeconds {
            DiagnosticsLog.shared.log("scheduler", "render debounced for \(followUpID.uuidString.prefix(8))")
            return
        }
        lastRenderAttempt[followUpID] = Date()

        Task { @MainActor in
            AlarmTelemetry.eventSync(.snoozeRenderStart, alarmID: followUpID)
            let renderStart = Date()
            let maxAttempts = 3
            let backoffs: [Duration] = [.seconds(1), .seconds(2), .seconds(4)]

            for attempt in 1...maxAttempts {
                let success = await self.attemptRender(followUpID: followUpID, attempt: attempt, timeout: .seconds(30))

                if success {
                    self.pendingFollowUpRenders.remove(followUpID)
                    AlarmTelemetry.eventSync(
                        .snoozeRenderComplete,
                        alarmID: followUpID,
                        elapsedMs: Int(Date().timeIntervalSince(renderStart) * 1000),
                        extra: "attempt=\(attempt)"
                    )
                    return
                }

                if attempt < maxAttempts {
                    let delay = backoffs[attempt - 1]
                    DiagnosticsLog.shared.log("scheduler", "snooze render attempt \(attempt) failed; retry in \(delay)")
                    try? await Task.sleep(for: delay)
                }
            }

            DiagnosticsLog.shared.log("scheduler", "snooze render exhausted \(maxAttempts) attempts; will retry on reconcile")
            AlarmTelemetry.eventSync(
                .snoozeRenderFailed,
                alarmID: followUpID,
                elapsedMs: Int(Date().timeIntervalSince(renderStart) * 1000),
                extra: "exhausted=\(maxAttempts)"
            )
        }
    }

    /// Single render attempt with a per-attempt timeout. Returns `true`
    /// on success. Creates a transient ModelContainer since this may run
    /// from a background intent path.
    private func attemptRender(followUpID: UUID, attempt: Int, timeout: Duration) async -> Bool {
        let renderTask = Task { @MainActor () -> Bool in
            do {
                let container = try ModelContainer(for: AffirmationAlarmApp.appSchema)
                let context = ModelContext(container)
                guard let profile = try context.fetch(FetchDescriptor<UserProfile>()).first else {
                    DiagnosticsLog.shared.log("scheduler", "snooze render attempt \(attempt): no profile found")
                    AlarmTelemetry.eventSync(.snoozeRenderFailed, alarmID: followUpID, extra: "no-profile attempt=\(attempt)")
                    return false
                }
                await MorningAudioRenderer.shared.renderForFollowUp(
                    followUpID: followUpID,
                    profile: profile,
                    modelContext: context
                )
                return true
            } catch {
                DiagnosticsLog.shared.log("scheduler", "snooze render attempt \(attempt) failed: \(error.localizedDescription)")
                AlarmTelemetry.eventSync(.snoozeRenderFailed, alarmID: followUpID, extra: "err=\(error.localizedDescription) attempt=\(attempt)")
                return false
            }
        }

        let timeoutTask = Task {
            try? await Task.sleep(for: timeout)
            renderTask.cancel()
        }

        let result = await renderTask.value
        timeoutTask.cancel()
        return result
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

    /// Handle an alarm that just started alerting. The morning affirmation
    /// sequence IS the alarm — a brief chime intro followed by the
    /// personalized spoken affirmations. No separate alarm tone loop;
    /// the user wakes up to their affirmations directly.
    ///
    /// - **Foregrounded**: cancel system alert, show ringing overlay
    ///   (Stop/Snooze), immediately begin affirmation playback. Stop
    ///   silences mid-playback; Snooze silences and reschedules.
    /// - **Backgrounded**: let the system alert handle it. The existing
    ///   Stop intent fires when the user interacts from the lock screen.
    private func handleFire(alarmID: UUID) async {
        defer { activeFireHandling.remove(alarmID) }

        DiagnosticsLog.shared.log("observer", "handleFire start \(alarmID.uuidString.prefix(8))")
        AlarmTelemetry.eventSync(.fire, alarmID: alarmID)

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarmID.uuidString])

        let soundsDir = MorningAudioRenderer.soundsDirectory()
        let morningURL = soundsDir.appendingPathComponent("morning-\(alarmID.uuidString).mp3")

        // If pre-rendered audio is missing (invalidated after last fire,
        // API timeout during refreshAll, first launch of a new build, etc.),
        // attempt a live render before giving up. Adds ~10-15s while the
        // system alarm rings, but the user hears affirmations instead of a
        // generic tone.
        if !FileManager.default.fileExists(atPath: morningURL.path) {
            DiagnosticsLog.shared.log("observer", "no pre-render — attempting live render for \(alarmID.uuidString.prefix(8))")
            await attemptLiveRender(alarmID: alarmID)
        }

        guard FileManager.default.fileExists(atPath: morningURL.path) else {
            AppLogger.alarm.info("observer: no morning render for \(alarmID.uuidString.prefix(8), privacy: .public); letting system sound continue")
            lastHandleFireOutcome = FireOutcome(outcome: "noMorningRender", date: Date())
            DiagnosticsLog.shared.log("observer", "no morning render — leaving system sound")
            AlarmTelemetry.eventSync(.fireNoRender, alarmID: alarmID)
            return
        }

        let label = alarmLabels[alarmID] ?? "Alarm"

        // Clear any stale lock screen action before starting playback.
        UserDefaults.standard.removeObject(forKey: "lockScreenAction")

        // Start the manual ringing Live Activity FIRST, while the alarm is
        // still alerting. iOS restricts `Activity.request` from arbitrary
        // background contexts but allows it during an active alarm-fire
        // event, so the order here matters — moving this after `cancel()`
        // causes the request to silently fail and the lock screen UI never
        // appears. See FB14894127 (April 2026 — still open).
        let ringingActivity = startRingingActivity(alarmID: alarmID, label: label)

        try? manager.cancel(id: alarmID)
        DiagnosticsLog.shared.log("observer", "cancelled system alarm; waiting for interruption end")

        let waited = await InterruptionWaiter.awaitEnd(timeout: .milliseconds(500))
        DiagnosticsLog.shared.log("observer", "interruption wait returned: \(waited ? "ended" : "timeout")")

        // Always show the ringing overlay so Stop/Snooze is available
        // whether the app is foregrounded or the user opens it mid-playback.
        ringingAlarmID = alarmID
        ringingAlarmLabel = label
        isPlayingMorningAudio = true
        VolumeBooster.startMonitoring()

        let playStart = Date()
        DiagnosticsLog.shared.log("observer", "playing affirmations for \(alarmID.uuidString.prefix(8))")
        AlarmTelemetry.eventSync(.playStart, alarmID: alarmID)

        // Set up the action stream so Stop/Snooze buttons can interrupt.
        let (stream, continuation) = AsyncStream<RingingAction>.makeStream()
        ringingContinuation = continuation

        // Play affirmations. If user presses Stop/Snooze during playback,
        // stopPlayback() is called from the button handler to silence audio.
        let playbackTask = Task {
            await AlarmAudioPlayer.shared.playMorningAndClosing(for: alarmID)
        }

        // Wait for either: user presses Stop/Snooze, OR playback finishes.
        let actionTask = Task { () -> RingingAction in
            for await a in stream { return a }
            return .stop
        }

        // Whichever completes first determines the action. The third task
        // polls UserDefaults for Stop/Snooze tapped on the lock screen
        // Live Activity (cross-process handoff from the widget intent).
        let result: RingingAction = await withTaskGroup(of: RingingAction.self) { group in
            group.addTask { _ = await playbackTask.value; return .stop }
            group.addTask { await actionTask.value }
            group.addTask { await Self.pollLockScreenAction() }
            let first = await group.next() ?? .stop
            group.cancelAll()
            return first
        }
        let action = result

        // Clean up: stop any remaining audio, dismiss overlay, end Live Activity.
        playbackTask.cancel()
        actionTask.cancel()
        ringingContinuation = nil
        await AlarmAudioPlayer.shared.stopPlayback()
        VolumeBooster.stopMonitoring()
        isPlayingMorningAudio = false
        ringingAlarmID = nil
        if let ringingActivity {
            nonisolated(unsafe) let activity = ringingActivity
            await activity.end(nil, dismissalPolicy: .immediate)
            DiagnosticsLog.shared.log("observer", "ended ringing Live Activity")
        }
        UserDefaults.standard.removeObject(forKey: "lockScreenAction")

        DiagnosticsLog.shared.log("observer", "handleFire done action=\(action)")
        lastHandleFireOutcome = FireOutcome(outcome: String(describing: action), date: Date())
        AlarmTelemetry.eventSync(
            .playComplete,
            alarmID: alarmID,
            elapsedMs: Int(Date().timeIntervalSince(playStart) * 1000),
            extra: "action=\(action)"
        )

        switch action {
        case .stop:
            MorningAudioRenderer.shared.invalidateAll()
            MissedAlarmDetector.recordSuccess(alarmID: alarmID)
            StreakService.recordSuccess()
            AlarmTelemetry.eventSync(.lastFireRecorded, alarmID: alarmID)

        case .snooze:
            MorningAudioRenderer.shared.invalidateAll()
            scheduleSnoozeFollowUp(originalAlarmID: alarmID)
            MissedAlarmDetector.recordSuccess(alarmID: alarmID)
            StreakService.recordSuccess()
            DiagnosticsLog.shared.log("observer", "snoozed \(alarmID.uuidString.prefix(8))")
        }

        BackgroundKeepAlive.shared.start()
        NotificationCenter.default.post(name: .didCompleteMorningPlayback, object: nil)
    }

    // MARK: - Ringing Live Activity

    private func startRingingActivity(alarmID: UUID, label: String) -> Activity<RingingAttributes>? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            DiagnosticsLog.shared.log("observer", "Live Activities disabled — skipping ringing activity")
            return nil
        }
        let attributes = RingingAttributes(alarmID: alarmID, label: label)
        let state = RingingAttributes.ContentState()
        let content = ActivityContent(state: state, staleDate: nil)
        do {
            let activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            DiagnosticsLog.shared.log("observer", "started ringing Live Activity \(activity.id)")
            return activity
        } catch {
            DiagnosticsLog.shared.log("observer", "ringing Live Activity failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Polls UserDefaults for a lock screen Stop/Snooze action written by
    /// the widget extension's `StopFromLockScreen` / `SnoozeFromLockScreen`
    /// intents. Returns when an action is found or the task is cancelled.
    private nonisolated static func pollLockScreenAction() async -> RingingAction {
        while !Task.isCancelled {
            if let action = UserDefaults.standard.string(forKey: "lockScreenAction") {
                UserDefaults.standard.removeObject(forKey: "lockScreenAction")
                return action == "snooze" ? .snooze : .stop
            }
            try? await Task.sleep(for: .milliseconds(250))
        }
        return .stop
    }

    // MARK: - Live render fallback

    /// Last-resort render when pre-rendered audio is missing at fire time.
    /// Creates a transient ModelContainer, fetches the alarm + profile, and
    /// asks MorningAudioRenderer to render synchronously. Takes ~10-15s
    /// (Claude API + TTS round-trip). If anything fails, the caller's
    /// existing guard falls through to the system tone.
    private func attemptLiveRender(alarmID: UUID) async {
        do {
            let container = try ModelContainer(for: AffirmationAlarmApp.appSchema)
            let context = ModelContext(container)

            let allAlarms = (try? context.fetch(FetchDescriptor<Alarm>())) ?? []
            guard let alarm = allAlarms.first(where: { $0.id == alarmID }) else {
                DiagnosticsLog.shared.log("observer", "live render: alarm not found")
                return
            }

            let profileDescriptor = FetchDescriptor<UserProfile>()
            guard let profile = (try? context.fetch(profileDescriptor))?.first else {
                DiagnosticsLog.shared.log("observer", "live render: no profile")
                return
            }

            let (filename, _) = await MorningAudioRenderer.shared.refresh(
                for: alarm,
                profile: profile,
                modelContext: context
            )
            DiagnosticsLog.shared.log("observer", "live render: \(filename != nil ? "success" : "failed")")
        } catch {
            DiagnosticsLog.shared.log("observer", "live render: container error \(error.localizedDescription)")
        }
    }

    // MARK: - Ringing action stream

    /// Build the per-ring `AsyncStream<RingingAction>`, install its
    /// continuation on `self.ringingContinuation`, and suspend until the
    /// first yielded action arrives. A sibling task escalates volume every
    /// 60 seconds; at t+5min it schedules a fallback AlarmKit alert (so the
    /// user still wakes up if auto-play subsequently fails) and yields
    /// `.stop` itself.
    ///
    /// The `finish()` at the top of the user Stop/Snooze paths closes the
    /// stream, which terminates the `for await` loop here immediately
    /// regardless of how many yields arrive in the interim. That's the
    /// property we want: the first yield wins, all other signals are
    /// silently absorbed.
    private func awaitRingingAction(alarmID: UUID) async -> RingingAction {
        let (stream, continuation) = AsyncStream<RingingAction>.makeStream()
        ringingContinuation = continuation

        // Pre-snooze chime at t+30s: a soft double-beep overlaid on the
        // alarm loop that gives a second, distinct cue before escalation.
        // Runs as a sibling task so it doesn't block or delay the 5-minute
        // timeout clock.
        let chimeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(30))
            if Task.isCancelled { return }
            await MainActor.run {
                guard let self, self.ringingContinuation != nil else { return }
                AlarmTelemetry.eventSync(.preSnoozeChime, alarmID: self.ringingAlarmID)
            }
            await AlarmAudioPlayer.shared.playChime()
        }

        let timeoutTask = Task { [weak self] in
            for minute in 1...5 {
                try? await Task.sleep(for: .seconds(60))
                if Task.isCancelled { return }
                await MainActor.run {
                    // `ringingContinuation == nil` means awaitRingingAction
                    // already broke out of its for-await (user pressed Stop
                    // or Snooze). Don't perform escalation side effects
                    // after that point.
                    guard let self, self.ringingContinuation != nil else { return }
                    VolumeBooster.boostToMax()
                    AlarmTelemetry.eventSync(
                        .escalation,
                        alarmID: self.ringingAlarmID,
                        extra: "minute=\(minute)"
                    )
                }
            }
            if Task.isCancelled { return }
            await MainActor.run {
                // Same guard as the escalation loop: if the user raced
                // us to Stop in the final MainActor hop, don't schedule a
                // fallback alert they no longer need.
                guard let self, self.ringingContinuation != nil else { return }
                let sn = self.alarmSoundNames[alarmID] ?? "alarm_gentle"
                self.scheduleFallbackAlert(alarmID: alarmID, soundName: sn)
                AlarmTelemetry.eventSync(.ringingTimeout, alarmID: self.ringingAlarmID)
                self.ringingContinuation?.yield(.stop)
                self.ringingContinuation?.finish()
            }
        }

        var result: RingingAction = .stop
        for await action in stream {
            result = action
            break
        }
        timeoutTask.cancel()
        chimeTask.cancel()
        ringingContinuation = nil
        return result
    }

    // MARK: - Fallback alert

    /// Schedule a lightweight system-level alarm 60 seconds from now as a
    /// safety net when the in-app ringing timed out after 5 minutes with
    /// no user interaction. If the affirmation playback that follows the
    /// auto-stop fails for any reason, the user still gets a system alert
    /// and has a second chance to wake up.
    private func scheduleFallbackAlert(alarmID: UUID, soundName: String) {
        let fallbackID = UUID()
        let fireDate = Date().addingTimeInterval(60)

        let presentation = AlarmPresentation(
            alert: AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: "Wake up!")
            )
        )
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: AffirmationAlarmMetadata(alarmID: fallbackID, label: "Fallback"),
            tintColor: AppTheme.sunsetOrange
        )
        let configuration = ScheduleConfiguration.alarm(
            schedule: AlarmKit.Alarm.Schedule.fixed(fireDate),
            attributes: attributes,
            stopIntent: StopAndPlayClosingIntent(alarmID: alarmID),
            sound: .named(soundName)
        )

        alarmSoundNames[fallbackID] = soundName
        alarmLabels[fallbackID] = "Fallback"

        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.manager.schedule(id: fallbackID, configuration: configuration)
                DiagnosticsLog.shared.log("scheduler", "fallback alert \(fallbackID.uuidString.prefix(8)) in 60s")
                AlarmTelemetry.eventSync(.fallbackScheduled, alarmID: fallbackID, extra: "for=\(alarmID.uuidString.prefix(8))")
            } catch {
                DiagnosticsLog.shared.log("scheduler", "fallback schedule failed: \(error.localizedDescription)")
            }
        }
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
            tintColor: AppTheme.sunsetOrange
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

// MARK: - Interruption waiter

/// One-shot helper that awaits the next `AVAudioSession.interruptionNotification`
/// with `.ended` type, or returns on timeout. Used by `handleFire` to
/// synchronize with AlarmKit's audio-release interruption rather than
/// racing against it with a fixed delay + retries.
///
/// Why: research (Apr 2026, Apple Developer Forums + Archive docs)
/// confirms the official pattern for "activate audio after another
/// session released" is to observe the interruption notification
/// rather than poll/retry. Retrying `setActive(true)` during the
/// interruption window throws "Session activation failed" repeatedly;
/// waiting for `.ended` lets us activate once and succeed.
///
/// Usage: `let ended = await InterruptionWaiter.awaitEnd(timeout: …)`
/// Returns `true` if we received `.ended` within the window, `false`
/// if the timeout fired first (no interruption happened, or is still
/// in progress).
private enum InterruptionWaiter {

    /// Register a NotificationCenter observer, await the first `.ended`
    /// notification (ignoring `.began`), and unregister on return.
    /// Returns `true` on notification, `false` on timeout.
    static func awaitEnd(timeout: Duration) async -> Bool {
        await withCheckedContinuation { continuation in
            let box = Box(continuation: continuation)

            let token = NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: AVAudioSession.sharedInstance(),
                queue: .main
            ) { notification in
                guard
                    let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                    let type = AVAudioSession.InterruptionType(rawValue: rawType),
                    type == .ended
                else { return }
                box.resume(value: true)
            }
            box.setToken(token)

            // Timeout. If the .ended notification arrives first, the
            // box.resumed guard prevents double-resume; if the timeout
            // wins, the observer is removed in resume() before the
            // continuation fires.
            Task {
                try? await Task.sleep(for: timeout)
                box.resume(value: false)
            }
        }
    }

    /// Reference-wrapped state shared between the NotificationCenter
    /// callback (@Sendable) and the timeout Task. Internal `NSLock`
    /// serializes mutation; `@unchecked Sendable` acknowledges we're
    /// managing the concurrency ourselves rather than via Swift's
    /// automatic checks.
    private final class Box: @unchecked Sendable {
        private let lock = NSLock()
        private let continuation: CheckedContinuation<Bool, Never>
        private var resumed = false
        private var token: NSObjectProtocol?

        init(continuation: CheckedContinuation<Bool, Never>) {
            self.continuation = continuation
        }

        func setToken(_ t: NSObjectProtocol) {
            lock.lock()
            defer { lock.unlock() }
            if resumed {
                // Already resumed (possible if notification fired
                // synchronously in addObserver). Tidy up the observer
                // that just got installed.
                NotificationCenter.default.removeObserver(t)
                return
            }
            token = t
        }

        func resume(value: Bool) {
            lock.lock()
            defer { lock.unlock() }
            guard !resumed else { return }
            resumed = true
            if let t = token {
                NotificationCenter.default.removeObserver(t)
                token = nil
            }
            continuation.resume(returning: value)
        }
    }
}
