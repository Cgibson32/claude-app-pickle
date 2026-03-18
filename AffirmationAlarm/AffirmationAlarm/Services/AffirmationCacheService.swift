import Foundation
import SwiftData

actor AffirmationCacheService {
    static let shared = AffirmationCacheService()

    func prefetchIfNeeded(modelContext: ModelContext, profile: UserProfile) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check if we have affirmations for today
        let todayKey = DateFormatters.dayKey(for: today)
        if !hasAffirmations(for: todayKey, in: modelContext) {
            await generateAndCache(for: today, profile: profile, modelContext: modelContext)
        }

        // Also prefetch for tomorrow
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
            let tomorrowKey = DateFormatters.dayKey(for: tomorrow)
            if !hasAffirmations(for: tomorrowKey, in: modelContext) {
                await generateAndCache(for: tomorrow, profile: profile, modelContext: modelContext)
            }
        }
    }

    func getAffirmations(for date: Date, modelContext: ModelContext) -> [Affirmation] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        let descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { affirmation in
                affirmation.generatedFor >= startOfDay && affirmation.generatedFor < endOfDay
            },
            sortBy: [SortDescriptor(\Affirmation.generatedFor)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getTodayAffirmations(modelContext: ModelContext) -> [Affirmation] {
        getAffirmations(for: Date(), modelContext: modelContext)
    }

    func getLatestAffirmations(modelContext: ModelContext) -> [Affirmation] {
        // Get today's affirmations, or fall back to most recent
        let today = getTodayAffirmations(modelContext: modelContext)
        if !today.isEmpty { return today }

        // Fall back to most recent affirmations
        var descriptor = FetchDescriptor<Affirmation>(
            sortBy: [SortDescriptor(\Affirmation.generatedFor, order: .reverse)]
        )
        descriptor.fetchLimit = AppConstants.maxAffirmationsPerDay

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func cleanOldAffirmations(modelContext: ModelContext) {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -14, to: Date()) else { return }

        let descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { affirmation in
                affirmation.generatedFor < cutoff
            }
        )

        if let old = try? modelContext.fetch(descriptor) {
            for affirmation in old {
                modelContext.delete(affirmation)
            }
            try? modelContext.save()
        }
    }

    // MARK: - Private

    private func hasAffirmations(for dayKey: String, in modelContext: ModelContext) -> Bool {
        guard let date = DateFormatters.dayKeyFormatter.date(from: dayKey) else { return false }
        return !getAffirmations(for: date, modelContext: modelContext).isEmpty
    }

    private func generateAndCache(for date: Date, profile: UserProfile, modelContext: ModelContext) async {
        do {
            let affirmationTexts = try await ClaudeAPIService.shared.generateAffirmations(
                name: profile.name,
                freeformGoals: profile.freeformGoals,
                categories: profile.selectedCategories,
                count: AppConstants.defaultAffirmationCount
            )

            let goalContext = "\(profile.freeformGoals) | \(profile.selectedCategories.joined(separator: ", "))"

            for text in affirmationTexts {
                let affirmation = Affirmation(
                    text: text,
                    generatedFor: date,
                    goalContext: goalContext
                )
                modelContext.insert(affirmation)
            }

            try? modelContext.save()
        } catch {
            print("Failed to generate affirmations: \(error)")
        }
    }
}
