import Foundation

/// Generates personalized morning affirmations via the Anthropic Messages
/// API. The request is built as a typed `Codable` payload so the wire
/// format is documented in the types themselves, and response parsing is
/// done through `JSONDecoder` with a strict `Codable` decoder — no more
/// dictionary traversal that fails silently on shape changes.
actor ClaudeAPIService {

    // MARK: - Public types

    struct GeneratedContent: Sendable {
        let affirmations: [String]
        let closing: String
    }

    struct RecentReflection: Sendable {
        let mood: Int           // 0 = tough, 4 = amazing
        let goodThing: String
        let gratitude: String
    }

    enum APIError: Error, LocalizedError {
        case noAPIKey
        case badURL
        case network(any Error)
        case httpStatus(Int)
        case malformedResponse

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "No API key configured"
            case .badURL: return "Invalid API URL"
            case .network(let error): return "Network error: \(error.localizedDescription)"
            case .httpStatus(let code): return "HTTP error: \(code)"
            case .malformedResponse: return "Malformed response from API"
            }
        }
    }

    // MARK: - Public API

    func generateAffirmations(
        name: String,
        goals: String,
        categories: [String],
        recentReflections: [RecentReflection],
        eveningIntention: String? = nil,
        count: Int,
        exclude: [String] = [],
        maxTokens: Int = AppConstants.maxTokens
    ) async throws -> GeneratedContent {
        guard let apiKey = APIKeyConfiguration.getAPIKey(), !apiKey.isEmpty else {
            DiagnosticsLog.shared.log("claude", "NO API KEY — check Settings → Diagnostics")
            throw APIError.noAPIKey
        }
        guard let url = URL(string: AppConstants.apiURL) else {
            throw APIError.badURL
        }

        let userMessage = buildUserMessage(
            name: name,
            goals: goals,
            categories: categories,
            recentReflections: recentReflections,
            eveningIntention: eveningIntention,
            count: count,
            exclude: exclude
        )

        let payload = MessagesRequest(
            model: AppConstants.apiModel,
            maxTokens: maxTokens,
            // Explicit 1.0 — Claude's default but stated for clarity.
            // High temperature is intentional: affirmations need variety,
            // and we're already constraining structure heavily via the
            // system prompt and exclude list. Bumping to 1.1+ risks JSON
            // formatting breaks.
            temperature: 1.0,
            system: Self.systemPrompt,
            messages: [.init(role: "user", content: userMessage)]
        )

        let request = try makeURLRequest(url: url, apiKey: apiKey, payload: payload)
        let data = try await perform(request)
        return try parseGeneratedContent(from: data)
    }

    // MARK: - Wire types

    /// Request body for `POST /v1/messages`.
    private struct MessagesRequest: Encodable {
        let model: String
        let maxTokens: Int
        let temperature: Double
        let system: String
        let messages: [Message]

        struct Message: Encodable {
            let role: String
            let content: String
        }

        enum CodingKeys: String, CodingKey {
            case model, temperature, system, messages
            case maxTokens = "max_tokens"
        }
    }

    /// Top-level response shape from `POST /v1/messages`. We only need the
    /// first text block's `.text`; everything else is ignored.
    private struct MessagesResponse: Decodable {
        let content: [ContentBlock]

        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }
    }

    /// Inner JSON Claude emits inside the text block — the model is
    /// instructed to return exactly this shape.
    private struct AffirmationPayload: Decodable {
        let affirmations: [String]
        let closing: String
    }

    // MARK: - Networking primitives

    private func makeURLRequest(
        url: URL,
        apiKey: String,
        payload: MessagesRequest
    ) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(AppConstants.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(payload)
        return request
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.network(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.malformedResponse
        }
        guard http.statusCode == 200 else {
            let body = String(data: data.prefix(300), encoding: .utf8) ?? ""
            DiagnosticsLog.shared.log("claude", "HTTP \(http.statusCode): \(body)")
            throw APIError.httpStatus(http.statusCode)
        }
        return data
    }

    /// Decode the outer Messages response, extract the text block, and
    /// decode the inner affirmation JSON. Any failure surfaces as
    /// `.malformedResponse` — the error is logged by the caller.
    private func parseGeneratedContent(from data: Data) throws -> GeneratedContent {
        let decoder = JSONDecoder()
        guard
            let outer = try? decoder.decode(MessagesResponse.self, from: data),
            let text = outer.content.first(where: { $0.type == "text" })?.text,
            let inner = text.data(using: .utf8),
            let payload = try? decoder.decode(AffirmationPayload.self, from: inner)
        else {
            let preview = String(data: data.prefix(300), encoding: .utf8) ?? "(binary)"
            DiagnosticsLog.shared.log("claude", "malformed response body: \(preview)")
            throw APIError.malformedResponse
        }
        return GeneratedContent(
            affirmations: payload.affirmations,
            closing: payload.closing
        )
    }

    // MARK: - Prompt assembly

    private func buildUserMessage(
        name: String,
        goals: String,
        categories: [String],
        recentReflections: [RecentReflection],
        eveningIntention: String?,
        count: Int,
        exclude: [String]
    ) -> String {
        let trimmedGoals = goals.trimmingCharacters(in: .whitespacesAndNewlines)

        // Goals are the PRIMARY signal. Hoisted above everything else and
        // repeated with an explicit directive so the model can't treat
        // them as equal-weight context with mood/reflections.
        var header: String
        if !trimmedGoals.isEmpty {
            header = """
            === USER GOALS (PRIMARY — every affirmation must reference these) ===
            \(trimmedGoals)
            ===
            """
        } else {
            header = "=== NO GOALS PROVIDED — write ritual-anchored affirmations about showing up, beginning, and keeping your word to yourself. See the NO-GOAL FALLBACK section in your instructions. ==="
        }

        var supporting: [String] = ["User name: \(name)"]

        // The intention block, if present, is the second-strongest signal —
        // strong enough that the model is told to call it back in the FIRST
        // affirmation specifically, while the rest stay goal-anchored.
        var intentionBlock = ""
        if let intent = eveningIntention?.trimmingCharacters(in: .whitespacesAndNewlines),
           !intent.isEmpty {
            intentionBlock = """

            === LAST NIGHT'S INTENTION (FIRST AFFIRMATION must call this back) ===
            \(intent)
            ===
            """
        }

        var exclusionBlock = ""
        if !exclude.isEmpty {
            let numbered = exclude.enumerated()
                .map { "\($0.offset + 1). \($0.element)" }
                .joined(separator: "\n")
            exclusionBlock = """

            === ALREADY USED — DO NOT REPEAT OR PARAPHRASE ANY OF THESE ===
            The user has already heard the following \(exclude.count) lines on prior mornings. Each new affirmation must use different phrasing, a different scene/metaphor, AND a different sentence opener than every line below. If your draft echoes any of these, rewrite it.
            \(numbered)
            ===
            """
        }

        return """
        Generate \(count) personalized morning affirmations for this person, following every rule in your instructions.

        \(header)
        \(intentionBlock)

        \(supporting.joined(separator: "\n"))
        \(exclusionBlock)

        REMINDERS before writing:
        1. Pick 2-4 concrete nouns/verbs from the goals block above. Every single affirmation (and the closing) must reference at least one of them by name. Generic encouragement that could apply to anyone is a failed output.
        2. KEEP IT SIMPLE — aim for 4-9 words per line, one idea each. A just-woken brain can't hold a long sentence. Plain words beat clever ones.
        3. Include at least ONE action trigger: "When you [real morning cue], you [first move toward the goal]." This is the line that gets them out of bed and moving.
        4. Vary every opener — no two affirmations may start the same way. Mix: "You are…" / "When you…" / "Your [X]…" / "Today, you…"
        5. Re-read the ALREADY USED list (if present). Each line must differ in PHRASING, SCENE, and STRUCTURE from every line there.
        6. Use the person's name (\(name)) in EXACTLY ONE affirmation — the strongest one.
        7. The closing pushes them into action — name the first thing they're about to go do.
        """
    }

    private static let moodLabels = ["tough", "meh", "okay", "good", "amazing"]

    private static func describe(reflection r: RecentReflection) -> String {
        let idx = max(0, min(moodLabels.count - 1, r.mood))
        return "mood=\(moodLabels[idx]), highlight=\"\(r.goodThing)\", grateful for=\"\(r.gratitude)\""
    }

    // MARK: - System prompt

    private static let systemPrompt = """
    You write morning affirmations that land emotionally — a MIX of two voices that alternate naturally within the same set:

    VOICE 1 — THE CHAMPION (roughly half the affirmations):
    Bold, direct, zero doubt. Like a coach in the tunnel before the biggest game of your life. Kobe mentality. Ali confidence. Short, punchy declarations stated as fact. Makes you want to jump out of bed and dominate.

    VOICE 2 — THE MENTOR (roughly the other half):
    Warm, knowing, deeply personal. Like a wise mentor who sees you clearly — your effort, your struggle, your growth — and reflects the truest version of you back. Tender but not soft. Honors the journey without being sentimental.

    The BEST sets weave both voices together so the listener feels BOTH fired up AND deeply seen. Don't cluster all champion lines together then all mentor lines — alternate them so the emotional texture shifts line to line.

    The user wakes up to your words SPOKEN ALOUD by a voice assistant. They need to FEEL something — AND get out of bed ready to ACT. Feeling good is not the finish line; moving is. Every set must point at action, not just emotion.

    === MANDATORY: THE ACTION TRIGGER ===

    At least ONE affirmation in every set must be an "action trigger" — it names a real morning moment and the first concrete move tied to their goal. This is the most important line in the set. Pattern: "When you [real cue], you [first small action]."

    Examples:
    - "When your feet hit the floor, you say the goal out loud."
    - "When you open your laptop, you start with the hardest thing first."
    - "When you lace up, you remember why you started."

    This works because linking a cue to an action makes the brain act automatically — it's the difference between feeling motivated and actually doing the thing.

    === MANDATORY: ANTI-REPETITION ===

    The user hears your affirmations every morning. If you write the same lines repeatedly — even paraphrased — they stop landing. Each new generation MUST feel genuinely fresh.

    Before writing, scan the "ALREADY USED" block in the user message carefully. Then:
    1. Avoid the exact phrasings you see there
    2. Avoid the same METAPHOR or IMAGE (if you used "fire" yesterday, use a different one today)
    3. Vary the SENTENCE STRUCTURE — mix short punches with longer builds
    4. Vary the QUALITY targeted — discipline today, confidence tomorrow, hunger next time

    Treat repetition as the cardinal failure.

    === CORE RULES ===

    - "You" voice only — never "I."
    - Every affirmation MUST reference the user's SPECIFIC goal. Pull concrete nouns and verbs from their goal text and use them. Generic encouragement that could apply to anyone = failed output.
    - Each affirmation targets ONE thing — one quality, one action, one truth. One idea per line, never two.
    - STATE IT AS FACT. Not "you might be" or "you're becoming" — you ARE. Present tense, already true.
    - SIMPLE AND SHORT. Aim for 4-9 words. A half-asleep brain can only hold one clear thought. If a line needs a comma to work, it's probably two ideas — cut it to one. Plain words over clever ones.
    - At least one line is an ACTION TRIGGER (see above) — a cue + first move.
    - Use the person's name in exactly ONE affirmation — make it the strongest, most personal line. Save it for maximum impact.
    - No hedging, no qualifiers, no "even when it's hard" softening. Bold declarations.

    === TONE ===

    Champion lines: Coach in the tunnel. Direct eye contact. Zero doubt. Bold, electric, specific.
    Mentor lines: Someone who's watched you grow. Warm authority. Sees what you can't see about yourself yet. Honest, specific, tender.

    BOTH voices are confident. The difference is energy — champion PUSHES, mentor HOLDS.

    NOT corporate. NOT generic. NOT LinkedIn or Hallmark. Both voices must reference the user's SPECIFIC goal.

    === STYLE ===

    - Voice patterns: "You are…" / "Your [thing] is…" / "Today, you…" / "[Name], you…" / "Nobody outworks you at…" / "This is what you were built for —" / "They don't see what you see —"
    - LENGTH: keep most lines 4-9 words. One or two can stretch to 12 for a mentor beat, never more. Simpler always wins.
    - Vary openers — no two start the same way.
    - No emojis. No quotation marks.
    - Closing: a short send-off that pushes them OUT the door and INTO action — not just "have a great day." Name the first thing they're about to go do toward their goal. Like a coach's last words as you walk onto the field. 6-12 words.

    === BANNED LANGUAGE ===

    These are weak. Never use them or close paraphrases:
    "You are enough" / "You are worthy" / "You are limitless" / "You are unstoppable" / "You are amazing" / "You attract abundance" / "You deserve happiness" / "The universe has your back" / "You shine your light" / "You manifest your dreams" / "You are blessed" / "You are on the right path" / "Everything happens for a reason" / "You got this" (too cliché)

    Also banned: anything that sounds like a LinkedIn post, a yoga class, or a Hallmark card.

    === EXAMPLES (Champion 🔥 and Mentor 🌊 alternating) ===

    (⚡ marks the required ACTION TRIGGER line)

    Goal: "become the best baseball player"
    🔥 "Your bat speed is a weapon."
    🌊 "Those late reps are in your swing now."
    ⚡ "When you grab your glove, you picture one clean hit."
    🔥 "Pressure is where you live."
    🌊 "Marcus, you were built for this."

    Goal: "grow my business to 1M revenue"
    🔥 "You close what others won't pitch."
    🌊 "Every rejection you took is compounding."
    ⚡ "When you open your laptop, you make the hard call first."
    🔥 "A million is a deadline, not a dream."
    🌊 "Your clarity is rare. Trust it."

    Goal: "lose 30 pounds"
    🔥 "You chose the hard thing. That's you now."
    🌊 "Your body is changing where you can't see yet."
    ⚡ "When you reach the kitchen, you drink water first."
    🔥 "Lighter starts today."
    🌊 "Midnight discipline built this."

    Goal: "be a better father"
    🔥 "You walk in, they light up. That's you."
    🌊 "Just trying makes you the dad they need."
    ⚡ "When you get home, phone down, eyes up."
    🔥 "You're the dad they'll brag about."
    🌊 "Your patience today, they keep forever."

    BAD (for any goal): "You are amazing." / "You are worthy." / "You are on a beautiful journey." (generic, flat, no specifics)

    === INTENTION CALLBACK ===

    If the user message contains a "LAST NIGHT'S INTENTION" block, the FIRST affirmation MUST reference it directly. Speak it back to them as already happening. Make it undeniable they were heard.

    === NO-GOAL FALLBACK ===

    When no goals are provided, write DISCIPLINE-ANCHORED affirmations — celebrate the fact that they set an alarm, they showed up, they're choosing to be intentional. Bold energy, same rules.

    GOOD: "You set this alarm. Most people didn't."
    GOOD: "Today isn't happening to you. You happen to it."
    GOOD (action trigger): "When your feet hit the floor, you stand up tall."
    BAD: "You are worthy of a good day." (soft, generic)

    === OUTPUT FORMAT ===

    Respond ONLY with valid JSON, no other text:
    {"affirmations": ["...", "..."], "closing": "..."}
    """
}
