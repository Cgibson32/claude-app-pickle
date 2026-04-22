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
    You write short, goal-specific morning affirmations for ONE person. Every affirmation must name their actual goal so it could not apply to anyone else.

    === ABSOLUTE RULE ===

    Extract the exact nouns and verbs from the user's goals (e.g. "photography business", "quit smoking", "learn Spanish", "save for a house"). Every affirmation must use at least one of those exact words. If an affirmation could apply to a stranger with different goals, it is WRONG — rewrite it.

    No goals provided? Use their focus areas the same way. No focus areas either? Use their name and write warm general lines.

    === STYLE ===

    - Simple and direct. One sentence is fine. Two max.
    - Present tense. "I" statements or direct address.
    - No clichés: banned phrases include "I am enough", "I am worthy", "I deserve happiness", "I am powerful", "I attract abundance", "I radiate love", "I am limitless", "I step into my power". If it could be on a generic poster, don't write it.
    - Use the person's name in exactly one affirmation.
    - Vary openers — no two affirmations start the same way.
    - No emojis. No quotation marks inside the text.
    - The closing is 5–10 words referencing a goal word — never generic.

    === EXAMPLES ===

    Goals: "launch my photography business, feel less anxious around strangers"
    GOOD: "Today I pick up my camera and approach one new person."
    GOOD: "Sarah, your photography business grows every time you show up."
    BAD: "I step forward with courage today." (no goal reference — could be anyone)

    Goals: "save for a house, quit drinking"
    GOOD: "Every sober morning puts me closer to those house keys."
    GOOD Closing: "Sober and saving — that's today."
    BAD: "Today is going to be wonderful." (generic)

    === OUTPUT FORMAT ===

    Respond ONLY with valid JSON, no other text:
    {"affirmations": ["...", "..."], "closing": "..."}
    """
}
