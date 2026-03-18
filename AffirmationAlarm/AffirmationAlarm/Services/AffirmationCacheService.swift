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

    func getFavoritedAffirmations(modelContext: ModelContext) -> [Affirmation] {
        let descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { affirmation in
                affirmation.isFavorited == true
            },
            sortBy: [SortDescriptor(\Affirmation.generatedFor, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getClosingMessage(for date: Date, modelContext: ModelContext) -> String? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        let descriptor = FetchDescriptor<DailyClosingMessage>(
            predicate: #Predicate { message in
                message.generatedFor >= startOfDay && message.generatedFor < endOfDay
            }
        )

        return (try? modelContext.fetch(descriptor))?.first?.message
    }

    func cleanOldAffirmations(modelContext: ModelContext) {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -14, to: Date()) else { return }

        // Clean old non-favorited affirmations
        let affirmationDescriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { affirmation in
                affirmation.generatedFor < cutoff && affirmation.isFavorited == false
            }
        )

        if let old = try? modelContext.fetch(affirmationDescriptor) {
            for affirmation in old {
                modelContext.delete(affirmation)
            }
        }

        // Clean old closing messages
        let closingDescriptor = FetchDescriptor<DailyClosingMessage>(
            predicate: #Predicate { message in
                message.generatedFor < cutoff
            }
        )

        if let old = try? modelContext.fetch(closingDescriptor) {
            for message in old {
                modelContext.delete(message)
            }
        }

        try? modelContext.save()
    }

    // MARK: - Private

    private func hasAffirmations(for dayKey: String, in modelContext: ModelContext) -> Bool {
        guard let date = DateFormatters.dayKeyFormatter.date(from: dayKey) else { return false }
        return !getAffirmations(for: date, modelContext: modelContext).isEmpty
    }

    private func generateAndCache(for date: Date, profile: UserProfile, modelContext: ModelContext) async {
        do {
            let response = try await ClaudeAPIService.shared.generateAffirmations(
                name: profile.name,
                freeformGoals: profile.freeformGoals,
                categories: profile.selectedCategories,
                count: AppConstants.defaultAffirmationCount
            )

            let goalContext = "\(profile.freeformGoals) | \(profile.selectedCategories.joined(separator: ", "))"

            for text in response.affirmations {
                let affirmation = Affirmation(
                    text: text,
                    generatedFor: date,
                    goalContext: goalContext
                )
                modelContext.insert(affirmation)
            }

            // Store the closing message
            let closingMessage = DailyClosingMessage(
                message: response.closing,
                generatedFor: date
            )
            modelContext.insert(closingMessage)

            try? modelContext.save()
        } catch {
            print("Failed to generate affirmations: \(error)")
        }
    }
}
