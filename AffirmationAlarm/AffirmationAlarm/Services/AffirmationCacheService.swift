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

        // Check if we already have today's GENERATED affirmations. Custom
        // affirmations the user typed on the home screen also live under
        // today's generatedFor date but must not count as a cache hit —
        // otherwise the first custom affirmation would short-circuit
        // generation and the user would only hear that one line.
        let descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { $0.generatedFor >= today && $0.generatedFor < tomorrow && $0.isCustom == false }
        )
        let existingGenerated = (try? modelContext.fetch(descriptor)) ?? []
        if !existingGenerated.isEmpty {
            // Also include any custom affirmations the user added today so
            // they get spoken alongside the cached generated ones.
            let customDescriptor = FetchDescriptor<Affirmation>(
                predicate: #Predicate { $0.generatedFor >= today && $0.generatedFor < tomorrow && $0.isCustom == true }
            )
            let todayCustoms = (try? modelContext.fetch(customDescriptor)) ?? []
            let closingDescriptor = FetchDescriptor<DailyClosingMessage>(
                predicate: #Predicate { $0.generatedFor >= today && $0.generatedFor < tomorrow }
            )
            let closingMessage = (try? modelContext.fetch(closingDescriptor))?.first
            return (existingGenerated + todayCustoms, closingMessage)
        }

        // Fetch recent context
        let recentGratitude = fetchRecent(GratitudeEntry.self, keyPath: \GratitudeEntry.date, modelContext: modelContext)
            .map(\.text)
        let recentIntentions = fetchRecent(DailyIntention.self, keyPath: \DailyIntention.date, modelContext: modelContext)
            .map(\.text)
        let recentReflections = fetchRecent(EveningReflection.self, keyPath: \EveningReflection.date, modelContext: modelContext)
            .map { ClaudeAPIService.RecentReflection(mood: $0.mood, goodThing: $0.goodThing, gratitude: $0.gratitude) }

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
            recentReflections: recentReflections,
            count: profile.affirmationCount
        )

        // Store generated affirmations. Defensive `prefix` guard: if Claude
        // returns more lines than the user asked for, clip to the requested
        // count so the spoken sequence stays the configured length.
        var affirmations: [Affirmation] = []
        let goalContext = ([profile.freeformGoals] + profile.selectedCategories).joined(separator: "; ")
        for text in content.affirmations.prefix(profile.affirmationCount) {
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
