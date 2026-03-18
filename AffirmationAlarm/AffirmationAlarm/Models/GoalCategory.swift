import Foundation

enum GoalCategory: String, CaseIterable, Codable, Identifiable {
    case successCareer = "Success & Career"
    case confidenceSelfWorth = "Confidence & Self-Worth"
    case loveRelationships = "Love & Relationships"
    case healthWellness = "Health & Wellness"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .successCareer: return "briefcase.fill"
        case .confidenceSelfWorth: return "star.fill"
        case .loveRelationships: return "heart.fill"
        case .healthWellness: return "leaf.fill"
        }
    }
}
