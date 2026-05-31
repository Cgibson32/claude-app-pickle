// `@preconcurrency` silences Swift 6 region-based isolation errors for
// AlarmKit's async APIs. `requestAuthorization()` and `schedule(id:_:)`
// are declared nonisolated and take an `AlarmConfiguration` containing
// a `(any LiveActivityIntent)?` existential — not yet `Sendable` in the
// AlarmKit SDK. This `@preconcurrency` import is Apple's sanctioned
// escape hatch until AlarmKit ships proper `sending` annotations.
import ActivityKit
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
/// Layer 1 — the alarm **sound** (from the system daemon):
///   `.named(alarm.soundName)` points to a bundled CAF — default is
///   `alarm_rise.caf`, a 30-sec musical wake-up track. Plays from the
///   lock screen automatically (even if the app process is dead) and
///   serves as the primary wake-up cue. If the observer catches the
///   fire event, it cancels the system sound after ~100-500ms and
///   takes over with the personalized affirmation sequence.
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

    /// Set once at launch from AffirmationAlarmApp.init so fire-time
    /// code reuses the app's container instead of creating transient ones
    /// (which can cause SQLite contention on the same store file).
    var appContainer: ModelContainer?

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

    /// `UserDefaults` key for the persisted set of snooze follow-up
    /// UUIDs. Persisted (not in-memory only) so that if the app process
    /// dies during the 9-minute snooze window — which `BackgroundKeepAlive`
    /// usually prevents but iOS can still force on memory pressure —
    /// the next process can recognize the follow-up's fire event and
    /// route to the snooze playback path.
    private static let snoozeFollowUpIDsKey = "snoozeFollowUpIDs"
    private static let firedOneShotIDsKey = "firedOneShotIDs"

    private func firedOneShotIDs() -> Set<UUID> {
        let strings = UserDefaults.standard.stringArray(forKey: Self.firedOneShotIDsKey) ?? []
        return Set(strings.compactMap(UUID.init))
    }

    func markOneShotFired(_ id: UUID) {
        var ids = firedOneShotIDs()
        ids.insert(id)
        if ids.count > 20 { ids = Set(ids.suffix(20)) }
        UserDefaults.standard.set(ids.map(\.uuidString), forKey: Self.firedOneShotIDsKey)
    }

    private func clearOneShotFired(_ id: UUID) {
        var ids = firedOneShotIDs()
        ids.remove(id)
        UserDefaults.standard.set(ids.map(\.uuidString), forKey: Self.firedOneShotIDsKey)
    }

    private func snoozeFollowUpIDs() -> Set<UUID> {
        let strings = UserDefaults.standard.stringArray(forKey: Self.snoozeFollowUpIDsKey) ?? []
        return Set(strings.compactMap(UUID.init))
    }

    private func markSnoozeFollowUp(_ id: UUID) {
        var ids = snoozeFollowUpIDs()
        ids.insert(id)
        UserDefaults.standard.set(ids.map(\.uuidString), forKey: Self.snoozeFollowUpIDsKey)
    }

    private func clearSnoozeFollowUp(_ id: UUID) {
        var ids = snoozeFollowUpIDs()
        ids.remove(id)
        UserDefaults.standard.set(ids.map(\.uuidString), forKey: Self.snoozeFollowUpIDsKey)
    }

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

    // MARK: - Cross-process Stop/Snooze (Darwin notifications)

    /// Names for the Darwin notifications the Live Activity widget posts
    /// when its Stop/Snooze buttons are tapped. Darwin notifications cross
    /// process boundaries, so the widget extension can signal the running
    /// main-app process to halt audio IMMEDIATELY — without waiting for
    /// the app to foreground. This is what makes lock-screen Stop work
    /// while affirmations are mid-playback.
    static let stopDarwinName = "com.cgibson.affirmationalarm.lockscreen.stop"
    static let snoozeDarwinName = "com.cgibson.affirmationalarm.lockscreen.snooze"

    private var darwinObserversInstalled = false

    /// Install the Darwin observers once, at launch. The C callback can't
    /// capture context, so it routes back through the singleton.
    func installLockScreenSignalObservers() {
        guard !darwinObserversInstalled else { return }
        darwinObserversInstalled = true

        let center = CFNotificationCenterGetDarwinNotifyCenter()

        CFNotificationCenterAddObserver(
            center, nil,
            { _, _, _, _, _ in
                Task { @MainActor in AlarmKitScheduler.shared.userPressedStop() }
            },
            Self.stopDarwinName as CFString,
            nil, .deliverImmediately
        )
        CFNotificationCenterAddObserver(
            center, nil,
            { _, _, _, _, _ in
                Task { @MainActor in AlarmKitScheduler.shared.userPressedSnooze() }
            },
            Self.snoozeDarwinName as CFString,
            nil, .deliverImmediately
        )
        DiagnosticsLog.shared.log("scheduler", "lock-screen Darwin observers installed")
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

        // Assign a fresh pool file BEFORE scheduling so the notification
        // sound (which references morning-<alarmID>.mp3) has a real
        // audio file to play. The pool is pre-rendered well in advance
        // so this is always instant — no TTS at schedule time.
        let assigned = AffirmationPool.shared.assignToAlarm(alarmID: alarm.id)
        if !assigned {
            DiagnosticsLog.shared.log("scheduler", "pool empty when scheduling \(alarm.id.uuidString.prefix(8)) — notification may fall back")
        }

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
        startScheduledLiveActivity(for: alarm)
    }

    /// Start a Live Activity in "scheduled" state (isRinging=false) so
    /// it's on the lock screen BEFORE the alarm fires. At fire time,
    /// we update it to isRinging=true (which reveals Stop/Snooze).
    /// Starting here guarantees foreground context — iOS rejects
    /// Activity.request() from background, which is why the fire-time
    /// start was silently failing.
    private func startScheduledLiveActivity(for alarm: Alarm) {
        let id = alarm.id
        let label = alarm.label.isEmpty ? "Affirmation Alarm" : alarm.label
        Task { await Self.startLiveActivity(alarmID: id, label: label, ringing: false) }
    }

    /// All Live Activity mutation lives in `nonisolated static` helpers so
    /// the `Activity` values never cross from MainActor isolation into
    /// ActivityKit's nonisolated `update`/`end` (which Swift 6 flags as a
    /// data race). Params are Sendable (UUID/String/Bool) only.
    nonisolated private static func startLiveActivity(alarmID: UUID, label: String, ringing: Bool) async {
        // End any stale activity for this alarm first.
        for activity in Activity<RingingAttributes>.activities
            where activity.attributes.alarmID == alarmID {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        do {
            _ = try Activity<RingingAttributes>.request(
                attributes: RingingAttributes(alarmID: alarmID, label: label),
                content: ActivityContent(state: RingingAttributes.ContentState(isRinging: ringing), staleDate: nil),
                pushType: nil
            )
            DiagnosticsLog.shared.log("scheduler", "Live Activity started (ringing=\(ringing)) for \(alarmID.uuidString.prefix(8))")
        } catch {
            DiagnosticsLog.shared.log("scheduler", "Live Activity start FAILED: \(error.localizedDescription)")
        }
    }

    nonisolated private static func endLiveActivities(alarmID: UUID) async {
        for activity in Activity<RingingAttributes>.activities
            where activity.attributes.alarmID == alarmID {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// Reveal Stop/Snooze by flipping the existing activity to ringing.
    /// If none exists (expired or never started), start one as a fallback.
    nonisolated private static func updateLiveActivityToRinging(alarmID: UUID, label: String) async {
        if let activity = Activity<RingingAttributes>.activities.first(where: {
            $0.attributes.alarmID == alarmID
        }) {
            await activity.update(ActivityContent(
                state: RingingAttributes.ContentState(isRinging: true), staleDate: nil
            ))
            DiagnosticsLog.shared.log("observer", "Live Activity updated to ringing for \(alarmID.uuidString.prefix(8))")
        } else {
            await startLiveActivity(alarmID: alarmID, label: label, ringing: true)
            DiagnosticsLog.shared.log("observer", "Live Activity started at fire time for \(alarmID.uuidString.prefix(8))")
        }
    }

    /// Schedule a notification whose SOUND is the pre-rendered morning
    /// affirmation MP3. If handleFire runs (process alive), it cancels
    /// this notification before it fires and plays affirmations itself.
    /// If handleFire doesn't run (process dead), this notification fires
    /// and the user hears up to 30 seconds of personalized affirmations
    /// directly from the lock screen — no app launch needed.
    ///
    /// iOS caps notification sounds at 30 seconds. A typical morning
    /// sequence (greeting + 3-5 affirmations) fits within that window.
    /// If it's longer, iOS truncates — the user hears the greeting and
    /// first few affirmations, then taps Stop to hear the rest in-app.
    ///
    /// Uses `.criticalSoundNamed` so it bypasses silent mode + DND —
    /// the user registered for `.criticalAlert` during onboarding.
    /// Falls back to `.defaultCritical` if the MP3 doesn't exist yet
    /// (first launch before render completes).
    private func scheduleBackupNotification(for alarm: Alarm) {
        guard let fireDate = alarm.nextFireDate else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])

        let content = UNMutableNotificationContent()
        content.title = alarm.label.isEmpty ? "Affirmation Alarm" : alarm.label
        content.body = "Good morning — your affirmations are playing."
        content.interruptionLevel = .critical
        content.categoryIdentifier = NotificationDelegate.alarmCategoryID
        content.userInfo = ["alarmID": alarm.id.uuidString]

        let morningFile = "morning-\(alarm.id.uuidString).mp3"
        let soundsDir = MorningAudioRenderer.soundsDirectory()
        let morningURL = soundsDir.appendingPathComponent(morningFile)

        if FileManager.default.fileExists(atPath: morningURL.path) {
            content.sound = UNNotificationSound.criticalSoundNamed(
                UNNotificationSoundName(morningFile),
                withAudioVolume: 1.0
            )
            DiagnosticsLog.shared.log("scheduler", "backup notification with affirmation audio: \(morningFile)")
        } else {
            content.sound = .defaultCritical
            DiagnosticsLog.shared.log("scheduler", "backup notification with default sound (no render yet)")
        }

        // Fire 3 seconds after the alarm. Gives handleFire time to cancel
        // this notification if the process is alive — avoids double audio.
        let offsetDate = fireDate.addingTimeInterval(3)
        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: offsetDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        center.add(request)
        DiagnosticsLog.shared.log("scheduler", "backup notification for \(alarm.id.uuidString.prefix(8)) at \(alarm.timeString)+3s")
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
        endLiveActivity(for: alarm.id)
    }

    private func endLiveActivity(for alarmID: UUID) {
        Task { await Self.endLiveActivities(alarmID: alarmID) }
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

        let firedOneShots = firedOneShotIDs()

        for alarm in enabled {
            if liveIDs.contains(alarm.id) { continue }

            if alarm.repeatDays.isEmpty {
                if alarm.nextFireDate == nil || firedOneShots.contains(alarm.id) {
                    alarm.isEnabled = false
                    clearOneShotFired(alarm.id)
                    DiagnosticsLog.shared.log("reconcile", "one-shot \(alarm.id.uuidString.prefix(8)) fired — disabled")
                } else {
                    DiagnosticsLog.shared.log("reconcile", "one-shot \(alarm.id.uuidString.prefix(8)) missing from AlarmKit — rescheduling")
                    scheduleAlarm(alarm)
                }
            } else {
                DiagnosticsLog.shared.log("reconcile", "repeating \(alarm.id.uuidString.prefix(8)) missing from AlarmKit — rescheduling")
                scheduleAlarm(alarm)
            }
        }

        refreshLiveActivities(alarms: enabled)
    }

    /// Ensure every enabled alarm with an upcoming fire has a Live Activity.
    /// iOS auto-ends Live Activities after ~8 hours, so an alarm set at
    /// 10 PM for 6 AM may have lost its activity by fire time. This runs
    /// on every reconcile (app resume) to re-start any that expired.
    private func refreshLiveActivities(alarms: [Alarm]) {
        let activeAlarmIDs = Set(
            Activity<RingingAttributes>.activities.map { $0.attributes.alarmID }
        )

        for alarm in alarms where alarm.isEnabled {
            guard !activeAlarmIDs.contains(alarm.id) else { continue }
            startScheduledLiveActivity(for: alarm)
        }
    }

    /// Schedule only alarms that are NOT already live in AlarmKit.
    /// Unlike `scheduleAlarm` (which cancels first), this is safe to call
    /// on every app resume because it never cancels a pending alarm —
    /// eliminating the race where a cancel+reschedule near fire time kills
    /// the alarm for today and pushes it to tomorrow.
    /// Re-schedule backup notifications for all enabled alarms so they
    /// pick up the freshly-rendered morning MP3 as their sound. Called
    /// by `reconcileAlarmsWithSystem` after `refreshAll` completes.
    func refreshBackupNotifications(alarms: [Alarm]) {
        for alarm in alarms where alarm.isEnabled {
            scheduleBackupNotification(for: alarm)
        }
    }

    func scheduleIfMissing(alarms: [Alarm]) {
        let live = (try? manager.alarms) ?? []
        let liveIDs = Set(live.map(\.id))

        for alarm in alarms {
            if liveIDs.contains(alarm.id) {
                DiagnosticsLog.shared.log("scheduler", "\(alarm.id.uuidString.prefix(8)) already live — skipping")
                continue
            }
            DiagnosticsLog.shared.log("scheduler", "\(alarm.id.uuidString.prefix(8)) not in AlarmKit — scheduling")
            scheduleAlarm(alarm)
        }
    }

    // MARK: - Snooze follow-up

    /// Schedule a one-shot follow-up alarm using the original alarm's
    /// sound. Invoked by the in-app ringing UI's Snooze button and by
    /// `SnoozeMorningIntent`.
    ///
    /// The follow-up includes a Snooze button so the user can re-snooze
    /// indefinitely. The snooze greeting is TTS-rendered during the
    /// 9-minute window via `pendingFollowUpRenders`, which `RootView`
    /// drains on the next reconcile pass.
    func scheduleSnoozeFollowUp(originalAlarmID: UUID) {
        let followUpID = UUID()
        let snoozeSec = Double(AppConstants.snoozeDurationMinutes) * 60
        let fireDate = Date().addingTimeInterval(snoozeSec)
        let soundName = alarmSoundNames[originalAlarmID] ?? "alarm_rise"

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
        markSnoozeFollowUp(followUpID)

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
                guard let container = self.appContainer else {
                    DiagnosticsLog.shared.log("scheduler", "snooze render: no app container")
                    return false
                }
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

    /// Handle an alarm that just started alerting. Cancels the system
    /// alarm immediately (the bundled CAF acts as a brief wake chime),
    /// then plays the personalized greeting + affirmations.
    ///
    /// The in-app ringing overlay (Stop/Snooze) is shown unconditionally.
    /// Playback races against user action: pressing Stop silences
    /// mid-sentence; Snooze silences and reschedules. If neither is
    /// pressed, playback completes naturally and the overlay dismisses.
    private func handleFire(alarmID: UUID) async {
        let isSnoozeFollowUp = snoozeFollowUpIDs().contains(alarmID)
        defer {
            activeFireHandling.remove(alarmID)
            clearSnoozeFollowUp(alarmID)
        }

        DiagnosticsLog.shared.log("observer", "handleFire start \(alarmID.uuidString.prefix(8))\(isSnoozeFollowUp ? " (snooze follow-up)" : "")")
        AlarmTelemetry.eventSync(.fire, alarmID: alarmID)

        // NOTE: We do NOT cancel the backup notification here. If iOS
        // suspends this process between now and the moment AVAudioPlayer
        // starts (a real risk — see CLAUDE.md), cancelling here would
        // leave the user with total silence: bundled CAF cancelled, our
        // playback never starts, and notification cancelled. Instead we
        // cancel the notification only once we're committed to playing
        // (see runPlaybackWithOverlay). If handleFire dies before that,
        // the notification fires at the 3-second mark and the user
        // hears their affirmations from the lock screen.

        let soundsDir = MorningAudioRenderer.soundsDirectory()
        let morningURL = soundsDir.appendingPathComponent("morning-\(alarmID.uuidString).mp3")

        // Use the pre-rendered MP3 if it exists. The notification
        // fallback (which plays affirmations on the lock screen even
        // when the process is dead) references this same file — so we
        // must NOT delete or rename it here. Fresh generation happens
        // after playback via invalidateAll + reconcileAlarmsWithSystem.
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

        let label = alarmLabels[alarmID] ?? "Affirmation Alarm"

        // Cancel the AlarmKit alarm NOW to release its exclusive audio
        // session. Without this, our audio session activation will fail
        // (AlarmKit's daemon holds a non-mixable session while playing
        // the bundled CAF). The backup notification stays alive — it
        // only gets cancelled in onAudioConfirmed after our session
        // activates. If our session fails, the notification fires at
        // +3s and CAN play because AlarmKit's exclusive session is gone.
        UserDefaults.standard.removeObject(forKey: "lockScreenAction")
        UserDefaults.standard.removeObject(forKey: PendingPlayback.userDefaultsKey)

        try? manager.cancel(id: alarmID)
        DiagnosticsLog.shared.log("observer", "cancelled system alarm to release audio session")

        let waited = await InterruptionWaiter.awaitEnd(timeout: .milliseconds(500))
        DiagnosticsLog.shared.log("observer", "interruption wait: \(waited ? "ended" : "timeout")")

        // Always show the ringing overlay so Stop/Snooze is available
        // whether the app is foregrounded or the user opens it mid-playback.
        let playStart = Date()
        DiagnosticsLog.shared.log("observer", "playing affirmations for \(alarmID.uuidString.prefix(8))")
        AlarmTelemetry.eventSync(.playStart, alarmID: alarmID)

        let action = await runPlaybackWithOverlay(alarmID: alarmID, label: label, isSnoozeFollowUp: isSnoozeFollowUp)

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
            AffirmationPool.shared.assignToAlarm(alarmID: alarmID)
            MissedAlarmDetector.recordSuccess(alarmID: alarmID)
            StreakService.recordSuccess()
            markOneShotFired(alarmID)
            AlarmTelemetry.eventSync(.lastFireRecorded, alarmID: alarmID)

        case .snooze:
            // No pool re-assign for the snooze case — the follow-up
            // alarm has its own ID and gets its own (greeting-only)
            // render via the snooze code path.
            scheduleSnoozeFollowUp(originalAlarmID: alarmID)
            MissedAlarmDetector.recordSuccess(alarmID: alarmID)
            StreakService.recordSuccess()
            DiagnosticsLog.shared.log("observer", "snoozed \(alarmID.uuidString.prefix(8))")
        }

        BackgroundKeepAlive.shared.start()
        NotificationCenter.default.post(name: .didCompleteMorningPlayback, object: nil)
    }

    // MARK: - Shared playback + overlay

    /// Shows the ringing overlay (Stop/Snooze), plays affirmations (or
    /// snooze greeting + song), and races playback against user action.
    /// Returns the action that ended playback.
    ///
    /// Used by both `handleFire` (alarm observer path) and
    /// `playFromForegroundRetry` (lock-screen Stop intent path) so both
    /// get the same ringing UI with working Stop/Snooze buttons.
    private func runPlaybackWithOverlay(
        alarmID: UUID,
        label: String,
        isSnoozeFollowUp: Bool
    ) async -> RingingAction {
        ringingAlarmID = alarmID
        ringingAlarmLabel = label
        isPlayingMorningAudio = true
        VolumeBooster.startMonitoring()

        // Reveal Stop/Snooze: flip the existing (schedule-time) Live
        // Activity to isRinging=true, or start one if it expired. All
        // done in a nonisolated helper so no MainActor Activity value
        // crosses into ActivityKit's nonisolated methods (Swift 6).
        let ringingLabel = label
        Task { await Self.updateLiveActivityToRinging(alarmID: alarmID, label: ringingLabel) }

        // The backup notification stays alive until the audio player
        // confirms playback started. If playback fails, the notification
        // fires at +3s with the pre-rendered affirmations (and Stop/Snooze
        // action buttons).
        let cancelBackupNotification: @Sendable () -> Void = {
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: [alarmID.uuidString])
            DiagnosticsLog.shared.log("observer", "backup notification cancelled — audio confirmed playing")
        }

        let (stream, continuation) = AsyncStream<RingingAction>.makeStream()
        ringingContinuation = continuation

        let playbackTask = Task {
            let outcome: AlarmAudioPlayer.PlaybackOutcome
            if isSnoozeFollowUp {
                outcome = await AlarmAudioPlayer.shared.playSnoozeFollowUp(
                    for: alarmID,
                    onAudioConfirmed: cancelBackupNotification
                )
            } else {
                outcome = await AlarmAudioPlayer.shared.playMorningAndClosing(
                    for: alarmID,
                    onAudioConfirmed: cancelBackupNotification
                )
            }
            continuation.yield(.stop)
            continuation.finish()
            return outcome
        }

        let actionTask = Task { () -> RingingAction in
            for await a in stream { return a }
            return .stop
        }

        let chimeTask = Task {
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled else { return }
            AlarmTelemetry.eventSync(.preSnoozeChime, alarmID: alarmID)
            await AlarmAudioPlayer.shared.playChime()
        }

        let timeoutTask = Task { [weak self] in
            for minute in 1...5 {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let self, self.ringingContinuation != nil else { return }
                    VolumeBooster.boostToMax()
                    AlarmTelemetry.eventSync(.escalation, alarmID: alarmID, extra: "minute=\(minute)")
                    DiagnosticsLog.shared.log("observer", "volume escalation at minute \(minute)")
                }
            }
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self, self.ringingContinuation != nil else { return }
                let sn = self.alarmSoundNames[alarmID] ?? "alarm_rise"
                self.scheduleFallbackAlert(alarmID: alarmID, soundName: sn)
                AlarmTelemetry.eventSync(.ringingTimeout, alarmID: alarmID)
                self.ringingContinuation?.yield(.stop)
                self.ringingContinuation?.finish()
                DiagnosticsLog.shared.log("observer", "5-minute timeout — auto-stop + fallback alert scheduled")
            }
        }

        let result: RingingAction = await withTaskGroup(of: RingingAction.self) { group in
            group.addTask { _ = await playbackTask.value; return .stop }
            group.addTask { await actionTask.value }
            let first = await group.next() ?? .stop
            group.cancelAll()
            return first
        }

        playbackTask.cancel()
        actionTask.cancel()
        chimeTask.cancel()
        timeoutTask.cancel()
        ringingContinuation = nil
        await AlarmAudioPlayer.shared.stopPlayback()
        VolumeBooster.stopMonitoring()
        isPlayingMorningAudio = false
        ringingAlarmID = nil

        await Self.endLiveActivities(alarmID: alarmID)

        return result
    }

    /// Foreground retry path: called by `checkPendingMorningPlayback`
    /// when the lock-screen Stop intent foregrounded the app. Shows the
    /// same ringing overlay as `handleFire` so Stop/Snooze buttons work.
    func playFromForegroundRetry(alarmID: UUID) async {
        let label = alarmLabels[alarmID] ?? "Affirmation Alarm"
        let isSnoozeFollowUp = snoozeFollowUpIDs().contains(alarmID)

        DiagnosticsLog.shared.log("intent", "foreground retry with overlay for \(alarmID.uuidString.prefix(8))")

        let action = await runPlaybackWithOverlay(alarmID: alarmID, label: label, isSnoozeFollowUp: isSnoozeFollowUp)

        DiagnosticsLog.shared.log("intent", "foreground retry done action=\(action)")

        switch action {
        case .stop:
            AffirmationPool.shared.assignToAlarm(alarmID: alarmID)
            MissedAlarmDetector.recordSuccess(alarmID: alarmID)
            StreakService.recordSuccess()

        case .snooze:
            scheduleSnoozeFollowUp(originalAlarmID: alarmID)
            MissedAlarmDetector.recordSuccess(alarmID: alarmID)
            StreakService.recordSuccess()
        }

        clearSnoozeFollowUp(alarmID)
        BackgroundKeepAlive.shared.start()
        NotificationCenter.default.post(name: .didCompleteMorningPlayback, object: nil)
    }

    // MARK: - Live render fallback

    /// Last-resort render when pre-rendered audio is missing at fire time.
    /// Creates a transient ModelContainer, fetches the alarm + profile, and
    /// asks MorningAudioRenderer to render synchronously. Takes ~10-15s
    /// (Claude API + TTS round-trip). If anything fails, the caller's
    /// existing guard falls through to the system tone.
    private func attemptLiveRender(alarmID: UUID) async {
        do {
            guard let container = appContainer else {
                DiagnosticsLog.shared.log("observer", "live render: no app container")
                return
            }
            let context = ModelContext(container)

            let profileDescriptor = FetchDescriptor<UserProfile>()
            guard let profile = (try? context.fetch(profileDescriptor))?.first else {
                DiagnosticsLog.shared.log("observer", "live render: no profile")
                return
            }

            // Snooze follow-ups have no SwiftData `Alarm` record — they're
            // transient AlarmKit-only alarms. Render the snooze greeting
            // path (greeting only, no Claude API call needed) instead of
            // the regular morning path.
            if snoozeFollowUpIDs().contains(alarmID) {
                await MorningAudioRenderer.shared.renderForFollowUp(
                    followUpID: alarmID,
                    profile: profile,
                    modelContext: context
                )
                DiagnosticsLog.shared.log("observer", "live render: snooze greeting for \(alarmID.uuidString.prefix(8))")
                return
            }

            // Try the pool first — assign any available fresh slot to
            // this alarm. The pool is the primary source of truth; live
            // render is the last-resort fallback below.
            if AffirmationPool.shared.assignToAlarm(alarmID: alarmID) {
                DiagnosticsLog.shared.log("observer", "live render: assigned from pool")
                return
            }

            // Pool empty — try to refill on the fly. This is slow
            // (~10-15s) but only happens when the pool ran out, which
            // should be rare with the auto-refill threshold of 7.
            DiagnosticsLog.shared.log("observer", "live render: pool empty, refilling")
            await AffirmationPool.shared.refresh(profile: profile, modelContext: context)
            if AffirmationPool.shared.assignToAlarm(alarmID: alarmID) {
                DiagnosticsLog.shared.log("observer", "live render: assigned after refill")
                return
            }

            DiagnosticsLog.shared.log("observer", "live render: pool refill failed too")
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
            sound: .named(alarm.soundName)
        )
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
