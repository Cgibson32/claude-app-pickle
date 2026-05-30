import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String = ""
    var freeformGoals: String = ""
    var hasCompletedOnboarding: Bool = false
    var selectedCategoriesData: String = "[]"
    var ttsEnabled: Bool = true
    /// ElevenLabs voice ID — raw value of `ElevenLabsTTSService.Voice`.
    /// Default is Charlotte (warm & grounded); users can preview + switch
    /// in Voice Settings.
    var ttsVoice: String = "XB0fDUnXU5powFXDhCwa"
    var affirmationCount: Int = 3
    /// Raw value of `AffirmationBudget`. Stored as `String` (rather than
    /// the enum itself) so an existing SwiftData store migrates without a
    /// schema change — same pattern as `ttsVoice`. Defaults to `"medium"`,
    /// which matches today's hard-coded behavior exactly.
    var affirmationBudget: String = "medium"
    var createdAt: Date = Date.now
    var eveningReflectionEnabled: Bool = false
    var eveningReflectionHour: Int = 20
    var eveningReflectionMinute: Int = 0
    var alarmVolume: Float = 0.7

    var selectedCategories: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: Data(selectedCategoriesData.utf8))) ?? []
        }
        set {
            selectedCategoriesData = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    init() {}
}

/// How long the user wants each morning affirmation to be. Controls both
/// the Claude `max_tokens` budget (so the model isn't tempted to write
/// long form when the user asked for short) and the on-device TTS
/// `wordBudget` cap (so the spoken delivery stays tight).
///
/// Stored as a string raw value on `UserProfile.affirmationBudget`.
enum AffirmationBudget: String, CaseIterable, Sendable {
    case short, medium, long

    /// Displayed in the settings picker.
    var label: String {
        switch self {
        case .short: return "Short"
        case .medium: return "Medium"
        case .long: return "Long"
        }
    }

    /// One-line caption for the settings row.
    var caption: String {
        switch self {
        case .short: return "Crisp one-liners."
        case .medium: return "A balanced couple sentences (default)."
        case .long: return "More room to build momentum."
        }
    }

    /// Anthropic `max_tokens`. The default `medium` value matches the
    /// legacy `AppConstants.maxTokens` so existing users see no change
    /// until they opt into another budget.
    var claudeMaxTokens: Int {
        switch self {
        case .short: return 500
        case .medium: return 1000
        case .long: return 1800
        }
    }

    /// Multiplier applied to the per-affirmation word budget in
    /// `MorningAudioRenderer.wordBudget(for:)`. `medium` keeps today's
    /// numbers intact.
    var wordBudgetMultiplier: Double {
        switch self {
        case .short: return 0.65
        case .medium: return 1.0
        case .long: return 1.6
        }
    }
}

extension UserProfile {
    /// Type-safe accessor for `affirmationBudget`. Reading a malformed
    /// value (shouldn't happen, but could after a manual DB edit) falls
    /// back to `.medium` — the legacy default.
    var budget: AffirmationBudget {
        get { AffirmationBudget(rawValue: affirmationBudget) ?? .medium }
        set { affirmationBudget = newValue.rawValue }
    }
}
