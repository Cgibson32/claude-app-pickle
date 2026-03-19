import SwiftUI
import SwiftData

@main
struct AffirmationAlarmApp: App {
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
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Text("Hello")
                .font(.custom("Sora-Bold", size: 34))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.1, green: 0.1, blue: 0.18))
        }
        .modelContainer(modelContainer)
    }
}
