import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var experienceLevel: ExperienceLevel
    var playFrequency: PlayFrequency
    var playPreference: PlayPreference
    var struggles: [Struggle]
    var technicalWeaknesses: [TechnicalSkill]
    var mentalWeaknesses: [MentalSkill]
    var goals: [PlayerGoal]
    var playerIdentity: String
    var matchFrustrations: [MatchFrustration]
    var createdAt: Date
    var streakDays: Int
    var journalStreak: Int
    var totalSessions: Int

    static let empty = UserProfile(
        id: UUID(),
        name: "",
        experienceLevel: .intermediate,
        playFrequency: .threeToFour,
        playPreference: .doubles,
        struggles: [],
        technicalWeaknesses: [],
        mentalWeaknesses: [],
        goals: [],
        playerIdentity: "",
        matchFrustrations: [],
        createdAt: Date(),
        streakDays: 0,
        journalStreak: 0,
        totalSessions: 0
    )
}

enum ExperienceLevel: String, Codable, CaseIterable {
    case beginner = "Beginner (1.0-2.5)"
    case intermediate = "Intermediate (3.0-3.5)"
    case advanced = "Advanced (4.0-4.5)"
    case expert = "Expert (5.0+)"
}

enum PlayFrequency: String, Codable, CaseIterable {
    case oneToTwo = "1-2 times/week"
    case threeToFour = "3-4 times/week"
    case fiveOrMore = "5+ times/week"
    case daily = "Daily"
}

enum PlayPreference: String, Codable, CaseIterable {
    case doubles = "Doubles"
    case singles = "Singles"
    case both = "Both"
}

enum Struggle: String, Codable, CaseIterable {
    case consistency = "Consistency"
    case patience = "Patience"
    case shotSelection = "Shot Selection"
    case mentalToughness = "Mental Toughness"
    case nervesUnderPressure = "Nerves Under Pressure"
    case partnerCommunication = "Partner Communication"
    case courtPositioning = "Court Positioning"
    case emotionalControl = "Emotional Control"
}

enum TechnicalSkill: String, Codable, CaseIterable {
    case thirdShotDrop = "Third Shot Drops"
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
}

enum MentalSkill: String, Codable, CaseIterable {
    case confidence = "Confidence"
    case patience = "Patience"
    case frustrationControl = "Frustration Control"
    case partnerChemistry = "Partner Chemistry"
    case focusUnderPressure = "Focus Under Pressure"
    case bouncingBack = "Bouncing Back from Mistakes"
    case communication = "Communication"
    case selfTalk = "Self-Talk & Identity"
    case discipline = "Discipline"
    case processMindset = "Process Mindset"
}

enum PlayerGoal: String, Codable, CaseIterable {
    case winMoreGames = "Win More Games"
    case improveConsistency = "Improve Consistency"
    case stayCalm = "Stay Calm Under Pressure"
    case betterPartner = "Be a Better Partner"
    case advanceLevel = "Advance My Rating"
    case enjoyMore = "Enjoy the Game More"
    case competeTournaments = "Compete in Tournaments"
    case masterFundamentals = "Master Fundamentals"
}

enum MatchFrustration: String, Codable, CaseIterable {
    case unforced = "Unforced Errors"
    case partnerMistakes = "Partner's Mistakes"
    case losingLead = "Losing a Lead"
    case inconsistency = "My Inconsistency"
    case nervousness = "Nervousness"
    case badCalls = "Bad Line Calls"
    case slowStart = "Slow Starts"
    case mentalLetdown = "Mental Letdowns"
}
