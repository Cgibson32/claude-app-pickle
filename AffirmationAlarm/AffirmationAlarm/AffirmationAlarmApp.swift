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
        }
        .modelContainer(modelContainer)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showSequence = false
    @State private var showEveningReflection = false

    var body: some View {
        Group {
            if let profile = profiles.first, profile.hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingContainerView()
            }
        }
        .onAppear { ensureProfileExists() }
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
}
