import Foundation

/// Generic, universally positive affirmations used as a fallback when the
/// Claude API is unreachable (offline, server outage, rate limited, API key
/// invalid, etc.). When `AffirmationCacheService.fetchOrGenerate` catches
/// a Claude error, it pulls a deterministic daily set from this pool so
/// the user still wakes up to personalized-feeling content.
///
/// Selection is deterministic per calendar day: `selection(count:for:)`
/// uses the date as the seed so the same three affirmations play
/// throughout the day if the renderer runs multiple times, but tomorrow's
/// set is different from today's. Users get offline variety without the
/// set shifting mid-morning.
///
/// The pool intentionally contains only universally positive, goal-
/// agnostic affirmations — content that would work for any user
/// regardless of their freeform goals, categories, or recent reflections.
/// When Claude IS reachable, the user gets fully personalized lines from
/// `ClaudeAPIService.generateAffirmations`; this pool is the floor.
enum BundledAffirmationPool {
    /// 30 generic morning affirmations. Each line is under 15 words and
    /// safe to speak aloud via TTS at the `nova` voice without awkward
    /// pacing.
    static let affirmations: [String] = [
        "You are stronger than the challenges you will face today.",
        "Your presence makes the world a little brighter.",
        "Every breath you take is a fresh beginning.",
        "You are worthy of love, rest, and gentle care.",
        "Today, you move through the world with quiet courage.",
        "Your instincts are wise and you can trust them.",
        "Good things are gathering quietly on their way to you.",
        "You are allowed to take up space in this world.",
        "Every step forward counts, no matter how small.",
        "You are becoming exactly who you were meant to be.",
        "Your softness is a strength, not a weakness.",
        "You carry more light than you realize.",
        "Today's small choices are shaping a beautiful life.",
        "You have everything you need to meet this day.",
        "Peace begins with the way you treat yourself.",
        "You are allowed to rest without earning it.",
        "The love you give comes back to you in time.",
        "Your story is still unfolding, and it is a good one.",
        "You are exactly where you need to be right now.",
        "Your voice matters and deserves to be heard.",
        "You handle hard things with more grace than you know.",
        "Today is a new chance to be kind to yourself.",
        "You are learning, growing, and that is enough.",
        "Your dreams are worth the patience they require.",
        "You are not behind; you are on your own timeline.",
        "Small joys are not small — they are the whole point.",
        "You are allowed to change your mind and begin again.",
        "The way forward will reveal itself one step at a time.",
        "You are loved in ways you may not yet see.",
        "This day is yours — receive it gently."
    ]

    /// Generic closing lines, also selected deterministically per day.
    static let closings: [String] = [
        "Have a wonderful day.",
        "Rise gently and begin.",
        "Today is yours — receive it well.",
        "Step into the morning with kindness.",
        "May your day unfold with ease.",
        "Go softly into this new day."
    ]

    /// Deterministic per-day selection of `count` affirmations. The same
    /// date always returns the same set, so if the renderer runs twice
    /// on the same day the user doesn't hear a different lineup mid-morning.
    static func selection(count: Int, for date: Date = Date()) -> [String] {
        pick(from: affirmations, count: count, date: date)
    }

    /// Deterministic per-day selection of one closing line.
    static func closing(for date: Date = Date()) -> String {
        pick(from: closings, count: 1, date: date).first ?? "Have a wonderful day."
    }

    // MARK: - Private deterministic selection

    private static func pick(from pool: [String], count: Int, date: Date) -> [String] {
        let seed = Self.seed(for: date)
        var generator = SeededRandomGenerator(seed: seed)
        return Array(pool.shuffled(using: &generator).prefix(count))
    }

    /// Produce a stable `UInt64` seed from a date's year + day-of-year,
    /// so two calls to `selection(count:for:)` on the same calendar day
    /// return the same ordering.
    private static func seed(for date: Date) -> UInt64 {
        let calendar = Calendar.current
        let dayOfYear = UInt64(calendar.ordinality(of: .day, in: .year, for: date) ?? 1)
        let year = UInt64(calendar.component(.year, from: date))
        return year &* 1_000 &+ dayOfYear
    }
}

/// Simple linear-congruential PRNG — deterministic from an initial seed
/// and `Sendable` so it works in any actor context. Used by
/// `BundledAffirmationPool` to shuffle the pool reproducibly per day.
private struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid zero state — LCG would get stuck.
        self.state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
