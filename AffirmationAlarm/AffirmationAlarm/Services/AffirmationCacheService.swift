import Foundation
import SwiftData

/// Assembles the affirmation set for a single alarm fire.
///
/// Contract:
/// - Returns **exactly** `profile.affirmationCount` affirmations.
/// - Favorited affirmations (priority + rotation) fill slots first and are
///   NOT regenerated — they're the user's curated set.
/// - Remaining slots are freshly generated from Claude on every call, so
///   two alarms on the same day get different non-favorite lines.
/// - The closing message is also freshly generated on every call.
///
/// Old persisted generated affirmations (non-favorite, non-custom) are
/// garbage-collected on each call to keep SwiftData from growing unbounded.
@MainActor
class AffirmationCacheService {
    private let apiService = ClaudeAPIService()

    func fetchOrGenerate(
        for profile: UserProfile,
        modelContext: ModelContext,
        exclude: [String] = []
    ) async throws -> ([Affirmation], DailyClosingMessage?) {
        let requestedCount = max(1, profile.affirmationCount)

        // Step 1: pick favorites that will occupy slots in this fire.
        let selectedFavorites = selectFavorites(count: requestedCount, modelContext: modelContext)
        let favoriteSlots = selectedFavorites.count
        let needed = max(0, requestedCount - favoriteSlots)

        // Step 2: if all slots are filled by favorites (including any
        // user-typed custom lines — they're stored as priority favorites),
        // skip Claude generation entirely. Use a bundled closing to avoid
        // burning an API call purely for the 5–10 word tail.
        guard needed > 0 else {
            purgeOldGenerated(modelContext: modelContext)
            let closing = DailyClosingMessage(message: BundledAffirmationPool.closing())
            modelContext.insert(closing)
            return (selectedFavorites, closing)
        }

        // Step 3: generate the remaining `needed` affirmations fresh.
        let recentReflections = fetchRecentReflections(modelContext: modelContext)
        let content: ClaudeAPIService.GeneratedContent
        do {
            content = try await apiService.generateAffirmations(
                name: profile.name,
                goals: profile.freeformGoals,
                categories: profile.selectedCategories,
                recentReflections: recentReflections,
                count: needed,
                exclude: exclude,
                maxTokens: profile.budget.claudeMaxTokens
            )
        } catch {
            AppLogger.claude.error("generateAffirmations failed, using bundled pool: \(error.localizedDescription, privacy: .public)")
            DiagnosticsLog.shared.log("claude", "API FAILED: \(error.localizedDescription) — using generic fallback")
            let pooled = BundledAffirmationPool.selection(count: needed)
            content = ClaudeAPIService.GeneratedContent(
                affirmations: pooled,
                closing: BundledAffirmationPool.closing()
            )
        }

        // Step 4: purge yesterday's (and earlier) leftover generated rows
        // BEFORE inserting the new ones, so SwiftData doesn't accumulate.
        purgeOldGenerated(modelContext: modelContext)

        let goalContext = ([profile.freeformGoals] + profile.selectedCategories).joined(separator: "; ")
        var generated: [Affirmation] = []
        for text in content.affirmations.prefix(needed) {
            let a = Affirmation(text: text, generatedFor: Date(), goalContext: goalContext)
            modelContext.insert(a)
            generated.append(a)
        }

        // Step 5: assemble the final ordered list. Priority favorites first
        // (so the user hears their most important lines up top), then
        // rotation fav, then freshly generated fill. Exactly
        // `requestedCount` items — no more, no less.
        let finalSet = Array((selectedFavorites + generated).prefix(requestedCount))

        let closing = DailyClosingMessage(message: content.closing)
        modelContext.insert(closing)

        return (finalSet, closing)
    }

    // MARK: - Favorite selection

    /// Pick up to `count` favorites to occupy this fire's slots. Priority
    /// favorites come first (they're the ones the user starred with
    /// "always include"); if fewer than `count`, one random rotation fav
    /// is added. Returns in playback order.
    private func selectFavorites(count: Int, modelContext: ModelContext) -> [Affirmation] {
        let priorityDescriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { $0.favoriteType == 1 }
        )
        let priority = (try? modelContext.fetch(priorityDescriptor)) ?? []

        // If priority alone meets/exceeds the count, take priority and stop.
        if priority.count >= count {
            return Array(priority.prefix(count))
        }

        let rotationDescriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate { $0.favoriteType == 2 }
        )
        let rotation = (try? modelContext.fetch(rotationDescriptor)) ?? []

        var selected = priority
        if let pick = rotation.randomElement() {
            selected.append(pick)
        }
        return selected
    }

    // MARK: - Context gathering

    private func fetchRecentReflections(modelContext: ModelContext) -> [ClaudeAPIService.RecentReflection] {
        var descriptor = FetchDescriptor<EveningReflection>()
        descriptor.fetchLimit = 3
        let rows = (try? modelContext.fetch(descriptor)) ?? []
        return rows.map {
            ClaudeAPIService.RecentReflection(mood: $0.mood, goodThing: $0.goodThing, gratitude: $0.gratitude)
        }
    }

    // MARK: - Garbage collection

    /// Now that every fire generates a fresh set, the SwiftData table
    /// would grow without bound. Delete any generated (non-favorite,
    /// non-custom) row older than 1 day. Favorites and customs stay —
    /// they're the user's curated content.
    private func purgeOldGenerated(modelContext: ModelContext) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate {
                $0.generatedFor < cutoff
                    && $0.favoriteType == 0
                    && $0.isCustom == false
            }
        )
        if let old = try? modelContext.fetch(descriptor) {
            for entry in old {
                modelContext.delete(entry)
            }
        }

        // Also clear stale DailyClosingMessage rows — they're 1:1 with
        // fires now, not days, so they'd pile up similarly.
        let closingDescriptor = FetchDescriptor<DailyClosingMessage>(
            predicate: #Predicate { $0.generatedFor < cutoff }
        )
        if let oldClosings = try? modelContext.fetch(closingDescriptor) {
            for entry in oldClosings {
                modelContext.delete(entry)
            }
        }
    }
}
