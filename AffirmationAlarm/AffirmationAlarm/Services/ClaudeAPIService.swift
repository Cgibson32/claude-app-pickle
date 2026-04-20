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
        recentGratitude: [String],
        recentIntentions: [String],
        recentReflections: [RecentReflection],
        count: Int,
        exclude: [String] = []
    ) async throws -> GeneratedContent {
        guard let apiKey = APIKeyConfiguration.getAPIKey(), !apiKey.isEmpty else {
            throw APIError.noAPIKey
        }
        guard let url = URL(string: AppConstants.apiURL) else {
            throw APIError.badURL
        }

        let userMessage = buildUserMessage(
            name: name,
            goals: goals,
            categories: categories,
            recentGratitude: recentGratitude,
            recentIntentions: recentIntentions,
            recentReflections: recentReflections,
            count: count,
            exclude: exclude
        )

        let payload = MessagesRequest(
            model: AppConstants.apiModel,
            maxTokens: AppConstants.maxTokens,
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
        recentGratitude: [String],
        recentIntentions: [String],
        recentReflections: [RecentReflection],
        count: Int,
        exclude: [String]
    ) -> String {
        let trimmedGoals = goals.trimmingCharacters(in: .whitespacesAndNewlines)

        // Goals are the PRIMARY signal. Hoisted above everything else and
        // repeated with an explicit directive so the model can't treat
        // them as equal-weight context with gratitude/intentions/mood.
        var header: String
        if !trimmedGoals.isEmpty {
            header = """
            === USER GOALS (PRIMARY — every affirmation must reference these) ===
            \(trimmedGoals)
            ===
            """
        } else if !categories.isEmpty {
            header = """
            === USER FOCUS AREAS (PRIMARY — every affirmation must reference these) ===
            \(categories.joined(separator: ", "))
            ===
            """
        } else {
            header = "=== NO GOALS PROVIDED — write warm, general affirmations ==="
        }

        var supporting: [String] = ["User name: \(name)"]
        if !trimmedGoals.isEmpty, !categories.isEmpty {
            supporting.append("Secondary focus areas: \(categories.joined(separator: ", "))")
        }
        if !recentGratitude.isEmpty {
            supporting.append("Recent gratitude notes: \(recentGratitude.joined(separator: "; "))")
        }
        if !recentIntentions.isEmpty {
            supporting.append("Recent daily intentions: \(recentIntentions.joined(separator: "; "))")
        }
        if !recentReflections.isEmpty {
            let lines = recentReflections.map(Self.describe(reflection:))
            supporting.append("Recent evening reflections:\n- " + lines.joined(separator: "\n- "))
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
    You are a thoughtful morning coach writing affirmations for ONE specific person. Your only job is to produce affirmations so specific to this person's stated goals that they could not be used for anyone else.

    === PRIMARY RULE — GOAL TAILORING (non-negotiable) ===

    When the user provides goals, EVERY affirmation AND the closing must explicitly name a concrete noun, verb, or phrase drawn from those goals. Before writing anything, mentally list 2–4 key words or phrases from the goals block (e.g., "photography business", "anxious around strangers", "quit smoking", "run a 5K", "move to Portland", "learn Spanish"). Each affirmation must reference at least one of those words or phrases by name — not by synonym, not by vague gesture, by name.

    If an affirmation could be copy-pasted to a stranger with different goals and still make sense, it is a FAILED output. Rewrite it.

    If the user did not provide goals, fall back to their focus areas with the same rule — name them specifically.

    === SECONDARY RULES ===

    1. Present tense. Concrete, embodied language — the user should picture the moment.
    2. NO CLICHÉS. Banned: "I am enough", "I am worthy", "I deserve happiness", "I am powerful", "I attract abundance", "I am a magnet for success", "I radiate love", "I am limitless". If a phrase could appear on a generic Pinterest board, rewrite it.
    3. Vary sentence structure across the set — no two affirmations may share the same opener or rhythm.
    4. Use the user's name naturally in exactly ONE affirmation.
    5. If recent evening reflections show low mood ("tough" or "meh") or anxiety, acknowledge that gently in ONE affirmation and offer calm — without abandoning the goal reference.
    6. If recent reflections include a highlight or gratitude, build on it in ONE affirmation (momentum from yesterday into today) — still tied to the goal.
    7. Each affirmation: 1–2 sentences. No emojis. No quote marks inside the text.
    8. The closing message is 5–10 words, warm, and names at least one goal word/phrase — never generic.

    === WORKED EXAMPLES ===

    Goals: "launch my photography business, feel less anxious around strangers"
    GOOD: "My camera is a bridge — today I approach one stranger with curiosity instead of fear, and I capture the moment I was meant to see."
    GOOD: "Sarah, the photography business I'm building is real because I showed up for it yesterday, and I'm showing up again right now."
    BAD: "I am a confident photographer." (too short, generic, unembodied)
    BAD: "I am worthy of success." (banned cliché, zero goal reference)
    BAD: "I step forward with courage today." (FAILS PRIMARY RULE — no photography or stranger reference, could apply to anyone)

    Goals: "get healthier, stop doom-scrolling before bed"
    GOOD: "Tonight when my thumb reaches for the phone, I reach for the glass of water by my bed instead, and I fall asleep proud of that small choice."
    GOOD: "My body feels different when I close the screen at ten — lighter, quieter, mine again."
    BAD: "I make healthy choices." (vague, no phone/screen reference)
    BAD: "Every day I grow stronger." (FAILS PRIMARY RULE — could be for anyone)

    Goals: "save for a house, quit drinking"
    GOOD Closing: "House keys get closer every sober morning."
    BAD Closing: "Today is going to be wonderful." (generic — names no goal)

    === OUTPUT FORMAT ===

    Respond ONLY with valid JSON in this exact format, no prose around it:
    {"affirmations": ["...", "..."], "closing": "..."}
    """
}
