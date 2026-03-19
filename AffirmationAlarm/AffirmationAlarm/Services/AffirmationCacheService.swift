import Foundation
import SwiftData

actor AffirmationCacheService {
    private let apiService = ClaudeAPIService()

    func fetchOrGenerate(
        for profile: UserProfile,
        modelContext: ModelContext
    ) async throws -> ([Affirmation], DailyClosingMessage?) {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        // Check if we already have today's affirmations
        let descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { $0.generatedFor >= today && $0.generatedFor < tomorrow }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        if !existing.isEmpty {
            let closingDescriptor = FetchDescriptor<DailyClosingMessage>(
                predicate: #Predicate { $0.generatedFor >= today && $0.generatedFor < tomorrow }
            )
            let closingMessage = (try? modelContext.fetch(closingDescriptor))?.first
            return (existing, closingMessage)
        }

        // Fetch recent context
        let recentGratitude = fetchRecent(GratitudeEntry.self, keyPath: \GratitudeEntry.date, modelContext: modelContext)
            .map(\.text)
        let recentIntentions = fetchRecent(DailyIntention.self, keyPath: \DailyIntention.date, modelContext: modelContext)
            .map(\.text)

        // Include favorites for variety
        let favDescriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { $0.isFavorited }
        )
        let favorites = (try? modelContext.fetch(favDescriptor)) ?? []

        // Generate new affirmations
        let content = try await apiService.generateAffirmations(
            name: profile.name,
            goals: profile.freeformGoals,
            categories: profile.selectedCategories,
            recentGratitude: recentGratitude,
            recentIntentions: recentIntentions,
            count: profile.affirmationCount
        )

        // Store affirmations
        var affirmations: [Affirmation] = []
        let goalContext = ([profile.freeformGoals] + profile.selectedCategories).joined(separator: "; ")
        for text in content.affirmations {
            let a = Affirmation(text: text, generatedFor: Date(), goalContext: goalContext)
            modelContext.insert(a)
            affirmations.append(a)
        }

        // Add a random favorite if we have any
        if let randomFav = favorites.randomElement(), !affirmations.contains(where: { $0.text == randomFav.text }) {
            affirmations.append(randomFav)
        }

        // Store closing message
        let closing = DailyClosingMessage(message: content.closing)
        modelContext.insert(closing)

        // Clean old entries (14+ days)
        cleanOldEntries(modelContext: modelContext)

        return (affirmations, closing)
    }

    private func fetchRecent<T: PersistentModel>(
        _ type: T.Type,
        keyPath: KeyPath<T, Date>,
        modelContext: ModelContext,
        limit: Int = 3
    ) -> [T] {
        var descriptor = FetchDescriptor<T>()
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func cleanOldEntries(modelContext: ModelContext) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { $0.generatedFor < cutoff && !$0.isFavorited }
        )
        if let old = try? modelContext.fetch(descriptor) {
            for entry in old {
                modelContext.delete(entry)
            }
        }
    }
}
