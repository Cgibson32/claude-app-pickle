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
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query private var profiles: [UserProfile]
    @State private var showEveningReflection = false

    var body: some View {
        Group {
            if let profile = profiles.first, profile.hasCompletedOnboarding {
                // TODO: Re-enable paywall when subscription is configured in App Store Connect
                // if subscriptionManager.isSubscribed {
                //     HomeView()
                // } else {
                //     PaywallView()
                // }
                HomeView()
            } else {
                OnboardingContainerView()
            }
        }
        .onAppear {
            ensureProfileExists()
            reconcileAlarmsWithSystem()
        }
        .sheet(isPresented: $showEveningReflection) {
            EveningReflectionView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didTapEveningReflection)) { _ in
            showEveningReflection = true
        }
    }

    private func ensureProfileExists() {
        if profiles.isEmpty {
            modelContext.insert(UserProfile())
        }
    }

    /// Cross-reference SwiftData alarm rows with AlarmKit's live alarms on
    /// launch. `reconcile` auto-disables one-shot rows whose system entry is
    /// gone (they already fired) and re-arms repeating rows that got lost
    /// (e.g. first launch after an app update).
    ///
    /// Also refreshes the pre-rendered morning audio for every enabled
    /// alarm so the voice content stays fresh — if the file is older than
    /// 20 hours it's regenerated with today's Claude-tailored affirmations
    /// in the user's chosen voice. After rendering, every enabled alarm is
    /// re-scheduled so AlarmKit picks up the new sound file.
    private func reconcileAlarmsWithSystem() {
        let alarms = (try? modelContext.fetch(FetchDescriptor<Alarm>())) ?? []
        AlarmKitScheduler.shared.reconcile(alarms: alarms)

        guard let profile = (try? modelContext.fetch(FetchDescriptor<UserProfile>()))?.first,
              profile.hasCompletedOnboarding else {
            return
        }

        // Re-arm the evening reflection notification on launch in case
        // it was lost (OS update, permission change, etc.).
        if profile.eveningReflectionEnabled {
            EveningReflectionSchedulingService.schedule(
                hour: profile.eveningReflectionHour,
                minute: profile.eveningReflectionMinute
            )
        }

        let context = modelContext
        Task { @MainActor in
            await MorningAudioRenderer.shared.refreshAll(
                alarms: alarms,
                profile: profile,
                modelContext: context
            )
            // Re-schedule enabled alarms so AlarmKit picks up any freshly
            // rendered audio files.
            for alarm in alarms where alarm.isEnabled {
                AlarmKitScheduler.shared.scheduleAlarm(alarm)
            }
        }
    }
}
