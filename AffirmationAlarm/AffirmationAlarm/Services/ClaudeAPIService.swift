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
        count: Int
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
            count: count
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
        count: Int
    ) -> String {
        var context: [String] = ["User name: \(name)"]

        if !goals.isEmpty {
            context.append("Personal goals (their own words): \(goals)")
        }
        if !categories.isEmpty {
            context.append("Focus areas: \(categories.joined(separator: ", "))")
        }
        if !recentGratitude.isEmpty {
            context.append("Recent gratitude notes: \(recentGratitude.joined(separator: "; "))")
        }
        if !recentIntentions.isEmpty {
            context.append("Recent daily intentions: \(recentIntentions.joined(separator: "; "))")
        }
        if !recentReflections.isEmpty {
            let lines = recentReflections.map(Self.describe(reflection:))
            context.append("Recent evening reflections:\n- " + lines.joined(separator: "\n- "))
        }

        return """
        Generate \(count) personalized morning affirmations for this person, following every rule in your instructions.

        \(context.joined(separator: "\n"))
        """
    }

    private static let moodLabels = ["tough", "meh", "okay", "good", "amazing"]

    private static func describe(reflection r: RecentReflection) -> String {
        let idx = max(0, min(moodLabels.count - 1, r.mood))
        return "mood=\(moodLabels[idx]), highlight=\"\(r.goodThing)\", grateful for=\"\(r.gratitude)\""
    }

    // MARK: - System prompt

    private static let systemPrompt = """
    You are a thoughtful morning coach crafting affirmations for ONE specific person. Your job is to write affirmations that feel written FOR them, not pulled from a generic affirmation app.

    HARD RULES:
    1. Every affirmation must clearly reference the user's actual goals, focus areas, or recent context. If they said "start a photography business", the affirmation names photography. If they said "feel less anxious around strangers", the affirmation names that fear by name and reframes it.
    2. Present tense. Concrete, embodied language. The user should be able to picture the moment.
    3. NO CLICHÉS. Banned phrases include: "I am enough", "I am worthy", "I deserve happiness", "I am powerful", "I attract abundance", "I am a magnet for success", "I radiate love", "I am limitless". If a phrase could appear on a generic Pinterest board, rewrite it.
    4. Vary sentence structure across the set — no two affirmations may share the same opener or rhythm.
    5. Use the user's name naturally in exactly ONE of the affirmations.
    6. If recent evening reflections show a low mood ("tough" or "meh") or anxiety, acknowledge that gently in ONE affirmation and offer calm — do not pretend it didn't happen.
    7. If recent reflections include a "highlight" or gratitude, build on it in ONE affirmation (momentum from yesterday into today).
    8. Each affirmation: 1–2 sentences. No emojis. No quote marks inside the text.
    9. The closing message is 5–10 words, warm, and specific to their day ahead — not generic.

    EXAMPLE — user goal: "launch my photography business, feel less anxious around strangers"
    GOOD: "My camera is a bridge — today I approach one stranger with curiosity instead of fear, and I capture the moment I was meant to see."
    GOOD: "Sarah, the photography business I'm building is real because I showed up for it yesterday, and I'm showing up again right now."
    BAD: "I am a confident photographer." (too short, generic, unembodied)
    BAD: "I am worthy of success." (banned cliché, no goal connection)

    EXAMPLE — user goal: "get healthier, stop doom-scrolling before bed"
    GOOD: "Tonight when my thumb reaches for the phone, I reach for the glass of water by my bed instead, and I fall asleep proud of that small choice."
    BAD: "I make healthy choices." (vague, no concrete moment)

    Respond ONLY with valid JSON in this exact format, no prose around it:
    {"affirmations": ["...", "..."], "closing": "..."}
    """
}
