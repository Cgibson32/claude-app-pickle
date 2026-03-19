import Foundation

enum StreakService {
    struct StreakInfo {
        let current: Int
        let longest: Int
        let milestone: Int?
    }

    static func calculate(completions: [SequenceCompletion]) -> StreakInfo {
        let calendar = Calendar.current
        let sortedDates = Set(completions.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)

        guard !sortedDates.isEmpty else {
            return StreakInfo(current: 0, longest: 0, milestone: nil)
        }

        // Current streak
        var current = 0
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        if sortedDates.first == today || sortedDates.first == yesterday {
            current = 1
            var checkDate = sortedDates.first!
            for date in sortedDates.dropFirst() {
                let expected = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                if date == expected {
                    current += 1
                    checkDate = date
                } else {
                    break
                }
            }
        }

        // Longest streak
        var longest = 0
        var streak = 1
        for i in 1..<sortedDates.count {
            let expected = calendar.date(byAdding: .day, value: -1, to: sortedDates[i - 1])!
            if sortedDates[i] == expected {
                streak += 1
            } else {
                longest = max(longest, streak)
                streak = 1
            }
        }
        longest = max(longest, streak)

        // Milestone detection
        let milestones = [100, 30, 7]
        let milestone = milestones.first { current >= $0 && current == $0 }

        return StreakInfo(current: current, longest: longest, milestone: milestone)
    }

    static func milestoneMessage(for days: Int) -> String? {
        switch days {
        case 7: return "One week strong! You're building a habit."
        case 30: return "30 days! You're transforming your mornings."
        case 100: return "100 days! You're unstoppable."
        default: return nil
        }
    }
}
