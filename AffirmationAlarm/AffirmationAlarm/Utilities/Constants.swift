import Foundation

enum AppConstants {
    static let anthropicAPIURL = "https://api.anthropic.com/v1/messages"
    static let anthropicModel = "claude-opus-4-6-20250610"
    static let maxAffirmationsPerDay = 5
    static let defaultAffirmationCount = 3

    static let defaultSpeechRate: Float = 0.42
    static let defaultSpeechPitch: Float = 0.85
    static let defaultSpeechVolume: Float = 0.9

    static let greetingPostDelay: TimeInterval = 1.5
    static let affirmationPostDelay: TimeInterval = 2.0
    static let breathingPostDelay: TimeInterval = 3.0

    static let snoozeMinutes = 9
    static let scheduleDaysAhead = 7

    enum AlarmSounds: String, CaseIterable {
        case gentle = "alarm_gentle"
        case sunrise = "alarm_sunrise"
        case chime = "alarm_chime"
        case birds = "alarm_birds"

        var displayName: String {
            switch self {
            case .gentle: return "Gentle"
            case .sunrise: return "Sunrise"
            case .chime: return "Chime"
            case .birds: return "Birds"
            }
        }
    }
}
