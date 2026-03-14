import Foundation

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var mood: Mood
    var energyLevel: Int // 1-5
    var whatWentWell: String
    var patienceBreakdown: String
    var skillNeedingWork: String
    var communicationRating: Int // 1-5
    var emotionsDescription: String
    var improvementGoal: String
    var overallSessionRating: Int // 1-5
    var playType: PlayType
    var tags: [JournalTag]

    static let example = JournalEntry(
        id: UUID(),
        date: Date(),
        mood: .focused,
        energyLevel: 4,
        whatWentWell: "Stayed patient at the kitchen line and hit great third shot drops",
        patienceBreakdown: "Got frustrated after two unforced errors in game 3",
        skillNeedingWork: "Resets when attacked at body",
        communicationRating: 4,
        emotionsDescription: "Started calm, got tense mid-session, recovered well",
        improvementGoal: "Work on staying composed after losing a lead",
        overallSessionRating: 4,
        playType: .competitive,
        tags: [.patience, .thirdShotDrops, .composure]
    )
}

enum Mood: String, Codable, CaseIterable {
    case energized = "Energized"
    case focused = "Focused"
    case calm = "Calm"
    case confident = "Confident"
    case frustrated = "Frustrated"
    case tense = "Tense"
    case playful = "Playful"
    case grateful = "Grateful"

    var icon: String {
        switch self {
        case .energized: return "bolt.fill"
        case .focused: return "eye.fill"
        case .calm: return "leaf.fill"
        case .confident: return "star.fill"
        case .frustrated: return "cloud.fill"
        case .tense: return "exclamationmark.triangle.fill"
        case .playful: return "face.smiling.fill"
        case .grateful: return "heart.fill"
        }
    }
}

enum PlayType: String, Codable, CaseIterable {
    case recreational = "Recreational"
    case competitive = "Competitive"
    case drills = "Drills / Practice"
    case tournament = "Tournament"
}

enum JournalTag: String, Codable, CaseIterable {
    case patience = "Patience"
    case thirdShotDrops = "Third Shot Drops"
    case composure = "Composure"
    case communication = "Communication"
    case resets = "Resets"
    case dinks = "Dinks"
    case speedUps = "Speed-Ups"
    case positioning = "Positioning"
    case mentalToughness = "Mental Toughness"
    case confidence = "Confidence"
    case fun = "Had Fun"
    case improvement = "Felt Improvement"
}
