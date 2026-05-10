import Foundation

enum AppConstants {
    static let apiURL = "https://api.anthropic.com/v1/messages"
    static let apiModel = "claude-opus-4-7"
    static let apiVersion = "2023-06-01"
    static let maxTokens = 1000

    // OpenAI TTS — used for the nurturing cloud voice in the morning sequence.
    static let openAITTSURL = "https://api.openai.com/v1/audio/speech"

    static let snoozeDurationMinutes = 9

    static let moodEmojis = ["\u{1F614}", "\u{1F610}", "\u{1F642}", "\u{1F60A}", "\u{1F929}"]
    static let moodLabels = ["Tough", "Meh", "Okay", "Good", "Amazing"]

    /// Alarm sound choices, bundled as CAF files in the app bundle and
    /// referenced by `AlertConfiguration.AlertSound.named(...)` so they
    /// play directly from AlarmKit's system daemon — that means the
    /// sound plays even if the app process is dead, bypasses silent
    /// mode, and ignores Do Not Disturb.
    ///
    /// ## Musical wake-up sounds (30 sec, PCM CAF)
    /// These are trimmed Suno songs with fade-in/fade-out. The user
    /// hears a full musical wake-up from the lock screen automatically
    /// — much better than a beep, regardless of process state.
    ///
    /// ## Ambient sounds (legacy short tones)
    /// Kept for users who prefer a traditional wake-up cue.
    enum AlarmSound: String, CaseIterable {
        // Musical (Suno-generated, 30-sec wake-up tracks)
        case rise = "alarm_rise"
        case toast = "alarm_toast"
        case palms = "alarm_palms"
        case mirror = "alarm_mirror"

        // Ambient (short legacy tones)
        case gentle = "alarm_gentle"
        case sunrise = "alarm_sunrise"
        case chime = "alarm_chime"
        case birds = "alarm_birds"

        var displayName: String {
            switch self {
            case .rise: return "Rise"
            case .toast: return "Sunshine Toast"
            case .palms: return "Palm of Hands"
            case .mirror: return "Mirror Sunshine"
            case .gentle: return "Gentle Rise"
            case .sunrise: return "Sunrise"
            case .chime: return "Soft Chime"
            case .birds: return "Morning Birds"
            }
        }

        /// Whether this is one of the new 30-sec musical wake-up sounds.
        /// Used in the picker UI to group musical vs ambient options.
        var isMusical: Bool {
            switch self {
            case .rise, .toast, .palms, .mirror: return true
            case .gentle, .sunrise, .chime, .birds: return false
            }
        }
    }
}
