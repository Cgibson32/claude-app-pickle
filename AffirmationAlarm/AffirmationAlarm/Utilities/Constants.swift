import Foundation

enum AppConstants {
    static let apiURL = "https://api.anthropic.com/v1/messages"
    static let apiModel = "claude-sonnet-4-6"
    static let apiVersion = "2023-06-01"
    static let maxTokens = 1000

    // OpenAI TTS — used for the nurturing cloud voice in the morning sequence.
    static let openAITTSURL = "https://api.openai.com/v1/audio/speech"

    static let snoozeDurationMinutes = 9

    static let moodEmojis = ["\u{1F614}", "\u{1F610}", "\u{1F642}", "\u{1F60A}", "\u{1F929}"]
    static let moodLabels = ["Tough", "Meh", "Okay", "Good", "Amazing"]

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
