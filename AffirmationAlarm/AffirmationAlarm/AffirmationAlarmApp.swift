import SwiftUI
import SwiftData

@main
struct AffirmationAlarmApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let modelContainer: ModelContainer

    /// Single source of truth for the SwiftData schema. Shared by the main
    /// ModelContainer and by any transient containers (e.g. the snooze
    /// follow-up eager-render path in `AlarmKitScheduler`) so schema drift
    /// between the two can't cause migration mismatches.
    static let appSchema = Schema([
        UserProfile.self,
        Alarm.self,
        Affirmation.self,
        DailyClosingMessage.self,
        EveningReflection.self
    ])

    /// Build the persistent `ModelContainer`, recovering from an
    /// incompatible on-disk store by wiping it and trying again. Only the
    /// second attempt uses an in-memory fallback — if disk persistence
    /// itself is broken (rare) we at least stay launchable until the next
    /// update.
    private static func makeContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: appSchema, configurations: [config]) {
            return container
        }

        // Schema mismatch or corruption — delete the default store and
        // retry with fresh persistent storage so the user keeps a working
        // app and data persists across subsequent launches.
        wipeDefaultStore()
        if let container = try? ModelContainer(for: appSchema, configurations: [config]) {
            return container
        }

        do {
            let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: appSchema, configurations: [fallback])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    private static func wipeDefaultStore() {
        guard let appSupport = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return }
        for name in ["default.store", "default.store-shm", "default.store-wal"] {
            try? FileManager.default.removeItem(at: appSupport.appendingPathComponent(name))
        }
    }

    init() {
        modelContainer = Self.makeContainer()

        // Force the AlarmKitScheduler singleton to materialize at launch so
        // its alarmUpdates observer is running before the first alarm fires.
        _ = AlarmKitScheduler.shared

        // Start the keep-alive unconditionally at process launch. If no
        // alarms are enabled this is idempotent/harmless. If one IS
        // enabled, we close the race where the observer Task awaits
        // `alarmUpdates` with no audio session and iOS suspends us before
        // the first `.alerting` event arrives.
        Task { @MainActor in BackgroundKeepAlive.shared.start() }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var profiles: [UserProfile]
    @Query private var alarms: [Alarm]
    @State private var showEveningReflection = false
    @State private var scheduler = AlarmKitScheduler.shared
    @State private var missedAlarms: [Alarm] = []
    @State private var missedBannerDismissed = false

    var body: some View {
        Group {
            if let profile = profiles.first, profile.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingContainerView()
            }
        }
        .overlay(alignment: .top) {
            if !missedAlarms.isEmpty, !missedBannerDismissed {
                MissedAlarmBanner(
                    count: missedAlarms.count,
                    onDismiss: { missedBannerDismissed = true }
                )
                .padding(.horizontal, AppTheme.spacingLg)
                .padding(.top, AppTheme.spacingSm)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: missedAlarms.count)
        .animation(.easeInOut(duration: 0.2), value: missedBannerDismissed)
        .onAppear {
            ensureProfileExists()
            reconcileAlarmsWithSystem()
            checkForMissedAlarms()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkPendingMorningPlayback()
                // Always restart keep-alive on return-to-active. Idempotent
                // when already running; cheap to call when no alarms are
                // enabled (silent audio, volume 0, no DAC work). Closes
                // the window where an overnight interruption left us dead
                // and the user tapped to re-open.
                BackgroundKeepAlive.shared.start()
                checkForMissedAlarms()
            }
        }
        .sheet(isPresented: $showEveningReflection) {
            EveningReflectionView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didTapEveningReflection)) { _ in
            showEveningReflection = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .didCompleteMorningPlayback)) { _ in
            reconcileAlarmsWithSystem()
            // A fresh success wipes any stale "missed alarm" banner.
            missedAlarms = []
        }
        .fullScreenCover(isPresented: Binding(
            get: { scheduler.ringingAlarmID != nil },
            set: { _ in }
        )) {
            AlarmRingingView()
        }
    }

    /// Scan enabled alarms and surface ones whose most recent expected
    /// fire wasn't recorded as successful. One-shot banner per session —
    /// dismissal sticks until the user relaunches the app.
    private func checkForMissedAlarms() {
        guard !missedBannerDismissed else { return }
        let allAlarms = (try? modelContext.fetch(FetchDescriptor<Alarm>())) ?? []
        let missed = MissedAlarmDetector.detect(alarms: allAlarms)
        if missed.isEmpty {
            missedAlarms = []
            return
        }
        if missed.map(\.id) != missedAlarms.map(\.id) {
            missedAlarms = missed
            for alarm in missed {
                AlarmTelemetry.event(
                    .missedAlarmDetected,
                    alarmID: alarm.id,
                    extra: "time=\(alarm.timeString)"
                )
            }
        }
    }

    private func ensureProfileExists() {
        if profiles.isEmpty {
            modelContext.insert(UserProfile())
        }
    }

    /// Fallback playback path: if the Stop-slide intent set a pending
    /// playback flag and the app opened, play from the foreground.
    private func checkPendingMorningPlayback() {
        guard let idString = UserDefaults.standard.string(forKey: PendingPlayback.userDefaultsKey),
              let alarmID = UUID(uuidString: idString) else { return }

        UserDefaults.standard.removeObject(forKey: PendingPlayback.userDefaultsKey)
        DiagnosticsLog.shared.log("intent", "foreground retry triggered for \(alarmID.uuidString.prefix(8))")

        Task {
            _ = await AlarmAudioPlayer.shared.playMorningAndClosing(for: alarmID)
        }
    }

    private func reconcileAlarmsWithSystem() {
        let allAlarms = (try? modelContext.fetch(FetchDescriptor<Alarm>())) ?? []
        AlarmKitScheduler.shared.reconcile(alarms: allAlarms)

        // Start background keep-alive if any alarm is enabled — this keeps
        // the app process alive so the alarmUpdates observer can detect
        // .alerting state and auto-play affirmation audio.
        if allAlarms.contains(where: \.isEnabled) {
            BackgroundKeepAlive.shared.start()
        }

        guard let profile = (try? modelContext.fetch(FetchDescriptor<UserProfile>()))?.first,
              profile.hasCompletedOnboarding else {
            return
        }

        if profile.eveningReflectionEnabled {
            EveningReflectionSchedulingService.schedule(
                hour: profile.eveningReflectionHour,
                minute: profile.eveningReflectionMinute
            )
        }

        let context = modelContext
        Task { @MainActor in
            await MorningAudioRenderer.shared.refreshAll(
                alarms: allAlarms,
                profile: profile,
                modelContext: context
            )

            let pending = AlarmKitScheduler.shared.pendingFollowUpRenders
            if !pending.isEmpty {
                for followUpID in pending {
                    await MorningAudioRenderer.shared.renderForFollowUp(
                        followUpID: followUpID,
                        profile: profile,
                        modelContext: context
                    )
                }
                AlarmKitScheduler.shared.clearPendingFollowUpRenders()
            }

            for alarm in allAlarms where alarm.isEnabled {
                AlarmKitScheduler.shared.scheduleAlarm(alarm)
            }
        }
    }
}

/// One-shot banner shown at the top of `RootView` when `MissedAlarmDetector`
/// thinks an enabled alarm's recent fire wasn't completed successfully.
/// The user dismisses it with the X; the banner doesn't come back until
/// another detection cycle on the next launch.
private struct MissedAlarmBanner: View {
    let count: Int
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingMd) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.sunsetOrange)
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(count == 1 ? "An alarm may have missed" : "\(count) alarms may have missed")
                    .font(AppTheme.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Open Settings → Diagnostics to review the event log.")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.spacingMd)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                        .stroke(AppTheme.sunsetOrange.opacity(0.5), lineWidth: 1)
                )
        )
    }
}
