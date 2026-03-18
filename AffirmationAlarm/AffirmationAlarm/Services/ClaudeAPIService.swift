import Foundation

actor ClaudeAPIService {
    static let shared = ClaudeAPIService()

    struct AffirmationResponse {
        let affirmations: [String]
    }

    enum APIError: Error, LocalizedError {
        case noAPIKey
        case invalidResponse
        case httpError(Int, String)
        case decodingError(String)
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "No API key configured. Add your Anthropic API key in Settings."
            case .invalidResponse:
                return "Received an invalid response from the API."
            case .httpError(let code, let message):
                return "API error (\(code)): \(message)"
            case .decodingError(let detail):
                return "Failed to parse affirmations: \(detail)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }

    func generateAffirmations(
        name: String,
        freeformGoals: String,
        categories: [String],
        count: Int = AppConstants.defaultAffirmationCount
    ) async throws -> [String] {
        guard let apiKey = APIKeyConfiguration.getAPIKey() else {
            throw APIError.noAPIKey
        }

        let systemPrompt = buildSystemPrompt(name: name, freeformGoals: freeformGoals, categories: categories, count: count)

        let requestBody: [String: Any] = [
            "model": AppConstants.anthropicModel,
            "max_tokens": 500,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": "Generate my morning affirmations for today."]
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: URL(string: AppConstants.anthropicAPIURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(httpResponse.statusCode, errorBody)
        }

        return try parseAffirmations(from: data)
    }

    // MARK: - Private

    private func buildSystemPrompt(name: String, freeformGoals: String, categories: [String], count: Int) -> String {
        var prompt = """
        You are a warm, encouraging life coach. Generate \(count) personalized morning affirmations for \(name).
        """

        if !freeformGoals.isEmpty {
            prompt += "\n\nTheir personal goals: \(freeformGoals)"
        }

        if !categories.isEmpty {
            prompt += "\n\nTheir focus areas: \(categories.joined(separator: ", "))"
        }

        prompt += """

        \nRules:
        - Each affirmation should be 1-2 sentences
        - Use language specific to their goals (e.g., basketball terminology for basketball goals, coding references for programming goals)
        - Be specific, not generic
        - Use present tense ("I am", "I attract", "I create")
        - Make them feel personal and achievable
        - Vary the affirmations — don't repeat themes from day to day
        - Return ONLY a JSON array of strings, no other text
        """

        return prompt
    }

    private func parseAffirmations(from data: Data) throws -> [String] {
        // Parse the Anthropic API response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw APIError.invalidResponse
        }

        // The text should be a JSON array of strings
        // Try to extract JSON from the response (handle potential markdown wrapping)
        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanedText.data(using: .utf8),
              let affirmations = try? JSONSerialization.jsonObject(with: jsonData) as? [String] else {
            throw APIError.decodingError("Could not parse affirmations from response: \(text)")
        }

        guard !affirmations.isEmpty else {
            throw APIError.decodingError("Received empty affirmations array")
        }

        return affirmations
    }
}
