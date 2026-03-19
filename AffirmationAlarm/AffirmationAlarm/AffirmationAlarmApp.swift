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
            Text("Hello")
                .font(.largeTitle)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.1, green: 0.1, blue: 0.18))
        }
        .modelContainer(modelContainer)
    }
}
