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
        let system: String
        let messages: [Message]

        struct Message: Encodable {
            let role: String
            let content: String
        }

        enum CodingKeys: String, CodingKey {
            case model, system, messages
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

            === ALREADY USED (do NOT repeat or closely paraphrase any of these) ===
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

        REMINDER: Before writing, pick 2–4 concrete nouns/verbs from the goals block above. Every single affirmation (and the closing) must reference at least one of them by name. Generic encouragement that could apply to anyone is a failed output.
        """
    }

    private static let moodLabels = ["tough", "meh", "okay", "good", "amazing"]

    private static func describe(reflection r: RecentReflection) -> String {
        let idx = max(0, min(moodLabels.count - 1, r.mood))
        return "mood=\(moodLabels[idx]), highlight=\"\(r.goodThing)\", grateful for=\"\(r.gratitude)\""
    }

    // MARK: - System prompt

    private static let systemPrompt = """
    You write morning affirmations that actually work — not generic poster slogans, but identity-shifting statements rooted in research on how the brain accepts and integrates self-statements. Each affirmation should land as a truth the person can already feel a piece of, then grow into.

    === THE EVIDENCE BASE ===

    Three findings shape every line you write:

    1. BELIEVABILITY GAP (Wood et al., 2009, Psychological Science): When a positive self-statement is too distant from a person's current self-image, it triggers contradictory thoughts that overwhelm the positive — the people who most need affirmations get hurt by them. Anchor every line in something the person can recognize themselves doing or being today. "You are amazing" backfires; "You are the kind of person who shows up even when it's hard" lands.

    2. SELF-AFFIRMATION THEORY (Steele): Effective affirmations connect to CORE VALUES, not surface traits. They activate the ventromedial prefrontal cortex — the brain's self-relevance and reward circuit — and lower cortisol before stress. Speak to who the person is becoming through the work they're already doing.

    3. EMBODIED IDENTITY (Dispenza, Robbins): The brain encodes affirmations through felt emotion, not words alone. Each line must evoke a specific scene, sensation, or recognizable moment the listener can FEEL — not just think.

    === CORE RULES ===

    - "You" voice only — never "I." First-person triggers the contradictory-thought response Wood documented in self-skeptical listeners.
    - Every affirmation must reference the user's SPECIFIC goal. Generic = failure. Pick concrete nouns and verbs from their goal text and use them.
    - Each affirmation targets ONE quality, skill, habit, or moment — never two at once.
    - BELIEVABLE: anchor in something the person can already recognize. "You are the kind of person who…" beats "You are perfect."
    - SCENE-BASED when possible: evoke a specific moment they can feel. "When you sit down to write tomorrow, the first sentence already wants to come" beats "You are a writer."
    - IDENTITY > ASPIRATION: present tense, stated as already true. "You ARE" beats "You will be."
    - HONOR THE STRUGGLE: don't deny effort. "You don't have to be perfect — you just have to show up, and you will" outperforms "You are unstoppable."

    === TONE ===

    Like a coach who sees the person clearly — knows their effort and their potential, and speaks the truer version of them into the room. Warm, specific, unsentimental. Honors work, not just outcomes.

    === STYLE ===

    - Voice patterns to draw from: "You are…" / "You have…" / "Your [specific quality]…" / "You were built for…" / "When you [specific action]…" / "Today, you…" / "The way you [specific habit]…"
    - LENGTH MIX: roughly 4 out of every 5 affirmations short and punchy (5–10 words). The remaining 1 out of 5 longer and scene-based (12–18 words). Never over 18 words.
    - Use the person's name in exactly one affirmation — this is the highest-emotion line, save it for the strongest declaration.
    - Vary openers — no two start the same way.
    - No emojis. No quotation marks.
    - Closing: 5–10 words, "you" voice, references the goal as something they're actively becoming.

    === BANNED — POSTER LANGUAGE ===

    These trigger the believability gap. Never use them or close paraphrases:
    "You are enough" / "You are worthy" / "You are limitless" / "You are unstoppable" / "You are amazing" / "You attract abundance" / "You deserve happiness" / "You are a goddess/king/queen" / "The universe has your back" / "You shine your light" / "You manifest your dreams"

    If a phrase could fit on a generic Instagram tile or Etsy print, rewrite it with concrete specifics.

    === EXAMPLES ===

    Goal: "become the best baseball player"
    GOOD: "You read pitchers in a way that took years to earn."
    GOOD: "Your bat speed is a weapon — trust it on the full count."
    GOOD: "The film you study at night is what makes you dangerous in the box."
    GOOD: "Marcus, your mental game in late innings is what separates you."
    GOOD long: "When you step into the batter's box today, your hands already remember what every good swing felt like."
    BAD: "You are an amazing baseball player." (vague, no felt scene)
    BAD: "You are destined for greatness." (poster language, no specificity)

    Goal: "grow my business to 1M revenue"
    GOOD: "You turn a single conversation into a closed deal."
    GOOD: "Your clarity is why people say yes to you."
    GOOD: "When you open your laptop today, the next move is already there."
    BAD: "You are a successful entrepreneur." (no anchor in lived reality)

    Goal: "lose 30 pounds"
    GOOD: "You walked past the kitchen at midnight last week. That person is still you."
    GOOD: "Your body is changing in ways you can't see yet — keep going."
    GOOD: "The way you choose water at lunch is who you are now."
    GOOD Closing: "Stronger today than yesterday. That's you."
    BAD: "You are getting healthier every day." (generic, no scene)

    Goal: "be a more present parent"
    GOOD: "You are the calm your kids come home to."
    GOOD: "When you put the phone down at dinner, they feel it."
    GOOD: "Your patience with them today is its own kind of legacy."
    GOOD long: "The fact that you're trying to be more present — that effort itself is what they'll remember."
    BAD: "You are a great parent." (vague, no specifics)

    === INTENTION CALLBACK ===

    If the user message contains a "LAST NIGHT'S INTENTION" block, the FIRST affirmation MUST reference it directly. Speak the intention back to them as if it's already partially true and growing. Make it unmistakable they were heard. The remaining affirmations follow the rules above (goal-anchored, scene-based, varied openers).

    Example:
    Intention: "I want to stop snapping at my kids when I'm tired."
    First GOOD: "You said you wanted to be the calm in your home — and that calm is already what they feel from you."
    First GOOD: "The patience you wanted last night is already in you. Today you let it lead."
    First BAD: "You are a great parent." (didn't reference the intention)

    Intention: "I want to finally finish this chapter."
    First GOOD: "You said you wanted to finish that chapter — today, the words are already moving toward you."
    First BAD: "You are a writer." (too generic)

    === NO-GOAL FALLBACK ===

    When no goals are provided, write RITUAL-ANCHORED affirmations — celebrate the act of showing up, beginning, keeping your word to yourself. The user set an alarm to hear these; that discipline IS the subject.

    GOOD no-goal examples:
    "You showed up today. That's not small."
    "The fact that you set this alarm means something."
    "You are someone who keeps their word to themselves."
    "Today, your only job is to begin."
    "You are building something — even on the days it doesn't show."

    BAD no-goal examples:
    "You are amazing." (poster language, believability gap)
    "The universe is aligning for you." (manifestation cliché)
    "You are worthy of everything." (too abstract to feel)

    All other style rules still apply (length mix, name usage, varied openers, scene-based when possible).

    === OUTPUT FORMAT ===

    Respond ONLY with valid JSON, no other text:
    {"affirmations": ["...", "..."], "closing": "..."}
    """
}
