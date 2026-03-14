import Foundation

struct Skill: Identifiable, Codable {
    let id: UUID
    let category: SkillCategory
    let title: String
    let explanation: String
    let coachingTips: [String]
    let mentalCues: [String]
    let commonMistakes: [String]
    let practiceIdeas: [String]
    let icon: String
    var isSaved: Bool
}

enum SkillCategory: String, Codable, CaseIterable {
    case thirdShotDrops = "Third Shot Drops"
    case resets = "Resets"
    case dinkPatterns = "Dink Patterns"
    case tracking = "Tracking"
    case speedUpTiming = "Speed-Up Timing"
    case courtPositioning = "Court Positioning"
    case transitionZone = "Transition Zone"
    case returns = "Returns"
    case serves = "Serves"
    case defense = "Defense"
    case partnerCommunication = "Partner Communication"

    var icon: String {
        switch self {
        case .thirdShotDrops: return "arrow.down.right.circle.fill"
        case .resets: return "arrow.counterclockwise.circle.fill"
        case .dinkPatterns: return "arrow.left.arrow.right.circle.fill"
        case .tracking: return "eye.circle.fill"
        case .speedUpTiming: return "bolt.circle.fill"
        case .courtPositioning: return "square.grid.2x2.fill"
        case .transitionZone: return "arrow.right.circle.fill"
        case .returns: return "arrow.uturn.backward.circle.fill"
        case .serves: return "figure.pickleball"
        case .defense: return "shield.fill"
        case .partnerCommunication: return "bubble.left.and.bubble.right.fill"
        }
    }

    var color: String {
        switch self {
        case .thirdShotDrops: return "ADFF2F"
        case .resets: return "2DD4BF"
        case .dinkPatterns: return "60A5FA"
        case .tracking: return "FBBF24"
        case .speedUpTiming: return "F87171"
        case .courtPositioning: return "A78BFA"
        case .transitionZone: return "34D399"
        case .returns: return "FB923C"
        case .serves: return "E879F9"
        case .defense: return "38BDF8"
        case .partnerCommunication: return "FFD700"
        }
    }
}

struct MentalLesson: Identifiable, Codable {
    let id: UUID
    let category: MentalCategory
    let title: String
    let content: String
    let keyTakeaways: [String]
    let exercises: [String]
    let icon: String
    var isSaved: Bool
}

enum MentalCategory: String, Codable, CaseIterable {
    case confidence = "Confidence"
    case patience = "Patience"
    case frustrationControl = "Frustration Control"
    case partnerChemistry = "Partner Chemistry"
    case focusUnderPressure = "Focus Under Pressure"
    case bouncingBack = "Bouncing Back"
    case communication = "Communication"
    case selfTalk = "Identity & Self-Talk"
    case discipline = "Discipline"
    case processMindset = "Process Mindset"

    var icon: String {
        switch self {
        case .confidence: return "star.fill"
        case .patience: return "hourglass"
        case .frustrationControl: return "wind"
        case .partnerChemistry: return "person.2.fill"
        case .focusUnderPressure: return "scope"
        case .bouncingBack: return "arrow.counterclockwise"
        case .communication: return "bubble.left.and.bubble.right.fill"
        case .selfTalk: return "brain.head.profile"
        case .discipline: return "checkmark.shield.fill"
        case .processMindset: return "gearshape.2.fill"
        }
    }

    var color: String {
        switch self {
        case .confidence: return "FFD700"
        case .patience: return "2DD4BF"
        case .frustrationControl: return "F87171"
        case .partnerChemistry: return "A78BFA"
        case .focusUnderPressure: return "60A5FA"
        case .bouncingBack: return "34D399"
        case .communication: return "FB923C"
        case .selfTalk: return "E879F9"
        case .discipline: return "ADFF2F"
        case .processMindset: return "38BDF8"
        }
    }
}
