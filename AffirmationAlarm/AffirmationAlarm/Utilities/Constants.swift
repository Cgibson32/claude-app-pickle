import Foundation

enum AppConstants {
    static let apiURL = "https://api.anthropic.com/v1/messages"
    static let apiModel = "claude-sonnet-4-20250514"
    static let apiVersion = "2023-06-01"
    static let maxTokens = 600

    static let defaultSpeechRate: Float = 0.42
    static let defaultSpeechPitch: Float = 0.85
    static let snoozeDurationMinutes = 9

    enum AlarmSound: String, CaseIterable {
        case gentle = "alarm_gentle"
        case sunrise = "alarm_sunrise"
        case chime = "alarm_chime"
        case birds = "alarm_birds"

        var displayName: String {
            switch self {
            case .gentle: return "Gentle Rise"
            case .sunrise: return "Sunrise"
            case .chime: return "Soft Chime"
            case .birds: return "Morning Birds"
            }
        }
    }
}
