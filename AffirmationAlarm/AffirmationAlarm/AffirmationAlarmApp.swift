import SwiftUI
import SwiftData

@main
struct AffirmationAlarmApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            UserProfile.self,
            Alarm.self,
            Affirmation.self,
            DailyClosingMessage.self,
            GratitudeEntry.self,
            DailyIntention.self,
            EveningReflection.self
        ])
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            do {
                let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(for: schema, configurations: [fallback])
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }

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
                .environment(SubscriptionManager.shared)
        }
        .modelContainer(modelContainer)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query private var profiles: [UserProfile]
    @Query private var alarms: [Alarm]
    @State private var showEveningReflection = false

    var body: some View {
        Group {
            if let profile = profiles.first, profile.hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingContainerView()
            }
        }
        .onAppear {
            ensureProfileExists()
            reconcileAlarmsWithSystem()
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
            }
        }
        .sheet(isPresented: $showEveningReflection) {
            EveningReflectionView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didTapEveningReflection)) { _ in
            showEveningReflection = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .didCompleteMorningPlayback)) { _ in
            // Re-schedule repeating alarms that cancel(id:) removed.
            reconcileAlarmsWithSystem()
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
            for alarm in allAlarms where alarm.isEnabled {
                AlarmKitScheduler.shared.scheduleAlarm(alarm)
            }
        }
    }
}
