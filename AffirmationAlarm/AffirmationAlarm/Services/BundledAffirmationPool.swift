import Foundation

/// Ritual-anchored fallback affirmations used when the Claude API is
/// unreachable (offline, server outage, rate limited, API key issue).
/// These celebrate the ACT of showing up — setting the alarm, keeping
/// your word to yourself, beginning — rather than making claims about
/// the listener's identity that could trigger the believability gap
/// (Wood et al., 2009). Every line is universally applicable regardless
/// of goals, but grounded enough to feel real rather than poster-tier.
///
/// Selection is deterministic per calendar day so the same set plays
/// throughout the day if the renderer runs multiple times.
enum BundledAffirmationPool {

    static let affirmations: [String] = [
        "You showed up today. That's not small.",
        "The fact that you set this alarm means something.",
        "You are someone who keeps their word to themselves.",
        "Today, your only job is to begin.",
        "You are building something — even on the days it doesn't show.",
        "Your future self is grateful you're here right now.",
        "You chose this morning. That's already discipline.",
        "The version of you that started this is still you.",
        "You don't have to be perfect to be moving forward.",
        "Your honest effort today outweighs perfect effort tomorrow.",
        "You are the kind of person who comes back.",
        "Today, showing up is the whole strategy.",
        "The way you talk to yourself this morning shapes everything.",
        "You are not behind. You are in motion.",
        "Small, on-purpose actions — that's how this works.",
        "You belong to this morning.",
        "You handle hard things with more skill than you credit yourself for.",
        "The morning belongs to you. Receive it.",
        "You are allowed to do this slowly.",
        "Your patience with yourself is a quiet strength.",
        "The good in you doesn't need to be earned.",
        "You are growing in ways you can't always see.",
        "Today, give yourself the same grace you give others.",
        "You are someone who chose to begin. That's rare.",
        "The way you carry this — it's admirable.",
        "You are allowed to be both tired and committed.",
        "One good morning leads to the next. This is that morning.",
        "You are not alone in finding this hard.",
        "The way forward reveals itself one honest step at a time.",
        "This day is yours. Begin it gently."
    ]

    static let closings: [String] = [
        "Now go — the day is waiting for you.",
        "Rise gently and begin.",
        "Today is yours. Make it count.",
        "One good morning at a time.",
        "You showed up. Now keep going.",
        "Step into it. You're ready."
    ]

    /// Deterministic per-day selection of `count` affirmations.
    static func selection(count: Int, for date: Date = Date()) -> [String] {
        pick(from: affirmations, count: count, date: date)
    }

    /// Deterministic per-day selection of one closing line.
    static func closing(for date: Date = Date()) -> String {
        pick(from: closings, count: 1, date: date).first ?? "Now go — the day is waiting for you."
    }

    // MARK: - Private deterministic selection

    private static func pick(from pool: [String], count: Int, date: Date) -> [String] {
        let seed = Self.seed(for: date)
        var generator = SeededRandomGenerator(seed: seed)
        return Array(pool.shuffled(using: &generator).prefix(count))
    }

    private static func seed(for date: Date) -> UInt64 {
        let calendar = Calendar.current
        let dayOfYear = UInt64(calendar.ordinality(of: .day, in: .year, for: date) ?? 1)
        let year = UInt64(calendar.component(.year, from: date))
        return year &* 1_000 &+ dayOfYear
    }
}

private struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
