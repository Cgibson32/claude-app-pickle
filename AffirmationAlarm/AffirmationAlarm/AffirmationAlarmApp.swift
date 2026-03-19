import SwiftUI
import SwiftData

@main
struct AffirmationAlarmApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            UserProfile.self, Alarm.self, Affirmation.self, DailyClosingMessage.self,
            GratitudeEntry.self, SequenceCompletion.self, DailyIntention.self, EveningReflection.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
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
    @Query private var profiles: [UserProfile]
    @State private var showAffirmationSequence = false
    @State private var showEveningReflection = false

    private var profile: UserProfile? {
        profiles.first
    }

    var body: some View {
        Group {
            if let profile, profile.hasCompletedOnboarding {
                HomeView()
                    .fullScreenCover(isPresented: $showAffirmationSequence) {
                        AffirmationSequenceView()
                    }
            } else {
                OnboardingContainerView()
            }
        }
        .onAppear {
            ensureProfileExists()
            observeNotificationLaunch()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didTapAlarmNotification)) { _ in
            showAffirmationSequence = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .didTapEveningReflection)) { _ in
            showEveningReflection = true
        }
        .sheet(isPresented: $showEveningReflection) {
            EveningReflectionView()
        }
    }

    private func ensureProfileExists() {
        if profiles.isEmpty {
            let profile = UserProfile()
            modelContext.insert(profile)
        }
    }

    private func observeNotificationLaunch() {
        if NotificationDelegate.shared.shouldShowAffirmationSequence {
            NotificationDelegate.shared.shouldShowAffirmationSequence = false
            showAffirmationSequence = true
        }
    }
}

extension Notification.Name {
    static let didTapAlarmNotification = Notification.Name("didTapAlarmNotification")
    static let didTapEveningReflection = Notification.Name("didTapEveningReflection")
}
