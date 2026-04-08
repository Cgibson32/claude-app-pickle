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
            EveningReflection.self,
            SequenceCompletion.self
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
    @State private var showSequence = false
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
        .fullScreenCover(isPresented: $showSequence) {
            AffirmationSequenceView()
        }
        .sheet(isPresented: $showEveningReflection) {
            EveningReflectionView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didTapAlarmNotification)) { _ in
            showSequence = true
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
    /// (e.g. first launch after an app update). See
    /// `AlarmKitScheduler.reconcile(alarms:)` for the full contract.
    private func reconcileAlarmsWithSystem() {
        let alarms = (try? modelContext.fetch(FetchDescriptor<Alarm>())) ?? []
        AlarmKitScheduler.shared.reconcile(alarms: alarms)
    }
}
