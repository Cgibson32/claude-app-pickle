import Foundation

/// Word-boundary profanity check for user-entered goal text.
/// Blocks the most common English obscenities without being
/// overly aggressive on mild language. Case-insensitive,
/// word-boundary-aware so "class" doesn't match "ass".
enum ProfanityFilter {

    private static let blockedWords: Set<String> = [
        "fuck", "fucking", "fucked", "fucker", "fuckers", "fucks",
        "shit", "shitting", "shitty", "bullshit",
        "ass", "asshole", "assholes",
        "bitch", "bitches", "bitching",
        "damn", "damned", "dammit", "goddamn",
        "dick", "dicks",
        "cock", "cocks",
        "pussy",
        "cunt", "cunts",
        "bastard", "bastards",
        "whore", "whores",
        "slut", "sluts",
        "nigger", "nigga", "niggas",
        "retard", "retarded", "retards",
        "fag", "faggot", "faggots",
        "motherfucker", "motherfuckers", "motherfucking",
        "wtf", "stfu", "lmfao"
    ]

    /// Returns `true` if the text contains any blocked word at a word
    /// boundary. Handles common evasions like extra spaces but not
    /// deliberate obfuscation (e.g., "f u c k") — the goal is to catch
    /// casual profanity, not adversarial input.
    static func containsProfanity(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let words = lowered.components(separatedBy: .alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return words.contains(where: { blockedWords.contains($0) })
    }
}
