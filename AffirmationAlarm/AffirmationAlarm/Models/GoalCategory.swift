import Foundation

enum GoalCategory: String, CaseIterable, Codable {
    case success = "Success & Career"
    case confidence = "Confidence & Self-Worth"
    case love = "Love & Relationships"
    case health = "Health & Wellness"

    var icon: String {
        switch self {
        case .success: return "star.fill"
        case .confidence: return "bolt.fill"
        case .love: return "heart.fill"
        case .health: return "leaf.fill"
        }
    }
}
