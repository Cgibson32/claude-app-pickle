import Foundation

struct AICoachInsight: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: InsightType
    let title: String
    let content: String
    let actionItems: [String]
    var isRead: Bool

    enum InsightType: String, Codable {
        case dailyCoaching = "Daily Coaching"
        case skillFocus = "Skill Focus"
        case mentalPattern = "Mental Pattern"
        case drillSuggestion = "Drill Suggestion"
        case encouragement = "Encouragement"
        case weeklyReview = "Weekly Review"
    }
}

struct CoachMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromCoach: Bool
    let timestamp: Date
}
