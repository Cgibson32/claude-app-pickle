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

    /// How many recent generated affirmations to feed Claude as the
    /// exclude list. Tuned so Claude has enough context to avoid recent
    /// repeats but not so much that the prompt bloats.
    private let historyExcludeCount = 60

    /// How many generated affirmation rows to keep in SwiftData as
    /// history. Old ones beyond this cap are pruned on every call.
    /// 200 ≈ 30-40 days of typical usage — long enough to prevent
    /// even monthly repeats.
    private let historyKeepCount = 200

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
            pruneClosingMessages(modelContext: modelContext)
            let closing = DailyClosingMessage(message: BundledAffirmationPool.closing())
            modelContext.insert(closing)
            return (selectedFavorites, closing)
        }

        // Step 3: gather the exclude list — combine any caller-passed
        // exclusions with our PERSISTED history. This is the key fix
        // for repeat affirmations: previously, purgeAllGenerated deleted
        // yesterday's set entirely, so Claude had no idea what it had
        // already written. Now we keep history and tell Claude exactly
        // which lines to avoid.
        let recentHistory = fetchRecentGeneratedTexts(
            limit: historyExcludeCount,
            modelContext: modelContext
        )
        let fullExclude = Array(Set(exclude + recentHistory))

        // Prune old generated rows (keep most recent N) before inserting
        // the new batch. Closing messages always get fully purged.
        pruneGeneratedHistory(modelContext: modelContext, keepRecent: historyKeepCount)
        pruneClosingMessages(modelContext: modelContext)

        let recentReflections = fetchRecentReflections(modelContext: modelContext)
        let intention = fetchFreshIntention(modelContext: modelContext)
        let content: ClaudeAPIService.GeneratedContent
        do {
            content = try await apiService.generateAffirmations(
                name: profile.name,
                goals: profile.freeformGoals,
                categories: profile.selectedCategories,
                recentReflections: recentReflections,
                eveningIntention: intention,
                count: needed,
                exclude: fullExclude,
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

    /// Returns the most recently written unconsumed intention if it's still
    /// "fresh" (within the last 24 hours) and marks it consumed so it only
    /// influences the very next alarm, then generation falls back to the
    /// user's standing goals.
    private func fetchFreshIntention(modelContext: ModelContext) -> String? {
        var descriptor = FetchDescriptor<EveningIntention>(
            predicate: #Predicate { $0.consumed == false },
            sortBy: [SortDescriptor(\EveningIntention.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let latest = (try? modelContext.fetch(descriptor))?.first else { return nil }
        let trimmed = latest.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let age = Date().timeIntervalSince(latest.createdAt)
        guard age >= 0, age < 24 * 60 * 60 else { return nil }
        latest.consumed = true
        return trimmed
    }

    // MARK: - History + garbage collection

    /// Fetch the texts of the most recent N generated affirmations,
    /// newest first. Used as Claude's exclude list to prevent repeats.
    private func fetchRecentGeneratedTexts(limit: Int, modelContext: ModelContext) -> [String] {
        var descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate {
                $0.favoriteType == 0
                    && $0.isCustom == false
            },
            sortBy: [SortDescriptor(\.generatedFor, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let rows = (try? modelContext.fetch(descriptor)) ?? []
        return rows.map(\.text)
    }

    /// Keep the most recent `keepRecent` generated affirmations as
    /// history, delete older ones. Replaces the old purgeAllGenerated
    /// which wiped the entire history — that caused Claude to repeat
    /// itself across days because it had no record of past output.
    private func pruneGeneratedHistory(modelContext: ModelContext, keepRecent: Int) {
        var descriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate {
                $0.favoriteType == 0
                    && $0.isCustom == false
            },
            sortBy: [SortDescriptor(\.generatedFor, order: .reverse)]
        )
        let rows = (try? modelContext.fetch(descriptor)) ?? []
        guard rows.count > keepRecent else { return }
        for entry in rows.dropFirst(keepRecent) {
            modelContext.delete(entry)
        }
    }

    /// Delete all closing messages. Unlike affirmations, we don't keep
    /// closing-message history because closings are short, less varied,
    /// and the exclusion benefit isn't worth the prompt-bloat tradeoff.
    private func pruneClosingMessages(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<DailyClosingMessage>()
        if let closings = try? modelContext.fetch(descriptor) {
            for entry in closings {
                modelContext.delete(entry)
            }
        }
    }
}
