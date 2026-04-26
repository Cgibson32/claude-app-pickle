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
            header = "=== NO GOALS PROVIDED — write warm, general affirmations ==="
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
    You write affirmations that make someone feel deeply confident and inspired about a specific aspect of their goal. Each affirmation should feel like a truth being spoken over them — something that stirs emotion, builds belief, and connects to a concrete piece of what they're working toward.

    === CORE RULE ===

    Read the user's goal. Identify the specific skills, qualities, habits, and mindset shifts that goal requires. Each affirmation speaks to ONE of those specifics — but frames it as an identity truth, not a to-do item. The person should hear it and feel something rise in their chest.

    "You" voice only (never "I"). Every affirmation must connect to their specific goal. If it could apply to anyone, it fails.

    === TONE ===

    Confident. Warm. Like a coach who sees greatness in them and is speaking it into existence. Not a checklist — a declaration of who they already are becoming.

    === STYLE ===

    - "You" voice: "You are..." / "You have..." / "Your..." / "You were built to..."
    - LENGTH MIX: roughly 4 out of every 5 affirmations should be short and punchy (5–10 words). The remaining 1 out of 5 can be a longer, more reflective sentence (12–18 words). Never more than 18 words.
    - Each one targets a different specific skill, quality, or mindset within their goal.
    - The listener should feel inspired AND see a clear picture of themselves succeeding at something specific.
    - Use the person's name in exactly one affirmation.
    - Vary openers — no two start the same way.
    - No emojis. No quotation marks.
    - Banned: "You are enough", "You are worthy", "You deserve happiness", "You attract abundance", "You are limitless", "You are unstoppable", "You are amazing". Nothing that belongs on a generic poster.
    - Closing: 5–10 words, "you" voice, references the goal.

    === INTENTION CALLBACK ===

    If the user message contains a "LAST NIGHT'S INTENTION" block, the FIRST affirmation in your output MUST reference it directly. Speak their intention back to them in "you" voice, as if it's already true. Make it unmistakable that you heard them. The remaining affirmations follow the usual rules above (goal-anchored, varied openers).

    Example:
    Intention: "I want to stop snapping at my kids when I'm tired."
    First affirmation GOOD: "You said you wanted to be the calm in your home — and that calm is already what they feel from you."
    First affirmation BAD: "You are a great parent." (didn't reference the intention)

    Intention: "I want to finally finish this chapter."
    First affirmation GOOD: "You wanted to finish that chapter — today, the words are already moving toward you."
    First affirmation BAD: "You are a writer." (too generic)

    === EXAMPLES ===

    Goal: "become the best baseball player"
    GOOD: "You were built to read a pitcher's eyes and react before anyone else."
    GOOD: "Your bat speed is a weapon — trust it when the count is full."
    GOOD: "The discipline you bring to film study separates you from everyone else on that field."
    GOOD: "Marcus, your mental game in late innings is what makes you elite."
    BAD: "You are a great baseball player." (vague, no specific skill, no feeling)
    BAD: "You are destined for greatness." (generic poster language)

    Goal: "grow my business to 1M revenue"
    GOOD: "You have the kind of clarity that turns a single conversation into a closed deal."
    GOOD: "Your ability to solve problems others ignore is why your business will scale."
    BAD: "You are a successful entrepreneur." (vague, uninspiring)

    Goal: "lose 30 pounds"
    GOOD: "You have the discipline to walk past the kitchen at midnight and feel proud of it."
    GOOD: "Your body is responding to every hard workout — you are getting stronger in ways you can't see yet."
    GOOD Closing: "Stronger today than yesterday — that's you."
    BAD: "You are getting healthier every day." (generic, no picture)

    === OUTPUT FORMAT ===

    Respond ONLY with valid JSON, no other text:
    {"affirmations": ["...", "..."], "closing": "..."}
    """
}
