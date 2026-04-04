import Foundation
import SwiftData

@MainActor
class AffirmationCacheService {
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

        // Fetch priority favorites (always included)
        let priorityDescriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { $0.favoriteType == 1 }
        )
        let priorityFavorites = (try? modelContext.fetch(priorityDescriptor)) ?? []

        // Fetch rotation favorites (one random pick)
        let rotationDescriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { $0.favoriteType == 2 }
        )
        let rotationFavorites = (try? modelContext.fetch(rotationDescriptor)) ?? []

        // Generate new affirmations
        let content = try await apiService.generateAffirmations(
            name: profile.name,
            goals: profile.freeformGoals,
            categories: profile.selectedCategories,
            recentGratitude: recentGratitude,
            recentIntentions: recentIntentions,
            count: profile.affirmationCount
        )

        // Store generated affirmations
        var affirmations: [Affirmation] = []
        let goalContext = ([profile.freeformGoals] + profile.selectedCategories).joined(separator: "; ")
        for text in content.affirmations {
            let a = Affirmation(text: text, generatedFor: Date(), goalContext: goalContext)
            modelContext.insert(a)
            affirmations.append(a)
        }

        // Add all priority favorites
        for fav in priorityFavorites where !affirmations.contains(where: { $0.text == fav.text }) {
            affirmations.insert(fav, at: 0)
        }

        // Add one random rotation favorite
        if let randomRotation = rotationFavorites.randomElement(),
           !affirmations.contains(where: { $0.text == randomRotation.text }) {
            affirmations.append(randomRotation)
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
            predicate: #Predicate { $0.generatedFor < cutoff && $0.favoriteType == 0 }
        )
        if let old = try? modelContext.fetch(descriptor) {
            for entry in old {
                modelContext.delete(entry)
            }
        }
    }
}
