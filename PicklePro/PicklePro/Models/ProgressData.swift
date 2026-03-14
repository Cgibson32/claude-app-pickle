import Foundation

struct ProgressData: Codable {
    var consistencyStreak: Int
    var journalingStreak: Int
    var totalPlaySessions: Int
    var totalJournalEntries: Int
    var skillProgress: [SkillProgress]
    var weeklyMoodTrend: [MoodEntry]
    var patienceScore: Double
    var confidenceScore: Double
    var focusedPlaySessions: Int

    static let example = ProgressData(
        consistencyStreak: 7,
        journalingStreak: 5,
        totalPlaySessions: 23,
        totalJournalEntries: 18,
        skillProgress: SkillProgress.examples,
        weeklyMoodTrend: MoodEntry.examples,
        patienceScore: 72,
        confidenceScore: 68,
        focusedPlaySessions: 15
    )
}

struct SkillProgress: Identifiable, Codable {
    let id: UUID
    let skill: String
    var progress: Double // 0-100
    var trend: Trend

    enum Trend: String, Codable {
        case improving, stable, declining
    }

    static let examples: [SkillProgress] = [
        SkillProgress(id: UUID(), skill: "Third Shot Drops", progress: 65, trend: .improving),
        SkillProgress(id: UUID(), skill: "Patience", progress: 72, trend: .improving),
        SkillProgress(id: UUID(), skill: "Resets", progress: 45, trend: .stable),
        SkillProgress(id: UUID(), skill: "Dink Patterns", progress: 58, trend: .improving),
        SkillProgress(id: UUID(), skill: "Court Positioning", progress: 70, trend: .stable),
        SkillProgress(id: UUID(), skill: "Confidence", progress: 68, trend: .improving),
    ]
}

struct MoodEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let mood: String
    let score: Int // 1-5

    static let examples: [MoodEntry] = {
        let calendar = Calendar.current
        return (0..<7).map { i in
            MoodEntry(
                id: UUID(),
                date: calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date(),
                mood: ["Focused", "Calm", "Energized", "Confident", "Focused", "Playful", "Grateful"][i],
                score: [4, 3, 5, 4, 4, 5, 4][i]
            )
        }
    }()
}
