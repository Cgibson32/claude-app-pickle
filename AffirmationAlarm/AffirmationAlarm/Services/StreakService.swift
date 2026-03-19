import Foundation
import SwiftData

class StreakService {
    static let shared = StreakService()

    nonisolated func recordCompletion(modelContext: ModelContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        // Check if already recorded today
        let descriptor = FetchDescriptor<SequenceCompletion>(
            predicate: #Predicate { completion in
                completion.date >= startOfDay && completion.date < endOfDay
            }
        )

        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            return
        }

        let completion = SequenceCompletion()
        modelContext.insert(completion)
        try? modelContext.save()
    }

    nonisolated func currentStreak(modelContext: ModelContext) -> Int {
        let completions = allCompletions(modelContext: modelContext)
        guard !completions.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // Check if today has a completion; if not, start from yesterday
        if !hasCompletion(on: checkDate, completions: completions, calendar: calendar) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }

        while hasCompletion(on: checkDate, completions: completions, calendar: calendar) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return streak
    }

    nonisolated func longestStreak(modelContext: ModelContext) -> Int {
        let completions = allCompletions(modelContext: modelContext)
        guard !completions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedDays = Set(completions.map { calendar.startOfDay(for: $0.date) }).sorted()

        var longest = 1
        var current = 1

        for i in 1..<sortedDays.count {
            if let expected = calendar.date(byAdding: .day, value: 1, to: sortedDays[i - 1]),
               calendar.isDate(expected, inSameDayAs: sortedDays[i]) {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }

        return longest
    }

    nonisolated func isMilestone(_ count: Int) -> Bool {
        [7, 30, 100].contains(count)
    }

    nonisolated func milestoneMessage(_ count: Int) -> String? {
        switch count {
        case 7: return "One week strong!"
        case 30: return "30 days of growth!"
        case 100: return "100 days — incredible!"
        default: return nil
        }
    }

    // MARK: - Private

    private nonisolated func allCompletions(modelContext: ModelContext) -> [SequenceCompletion] {
        let descriptor = FetchDescriptor<SequenceCompletion>(
            sortBy: [SortDescriptor(\SequenceCompletion.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private nonisolated func hasCompletion(on date: Date, completions: [SequenceCompletion], calendar: Calendar) -> Bool {
        completions.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
}
