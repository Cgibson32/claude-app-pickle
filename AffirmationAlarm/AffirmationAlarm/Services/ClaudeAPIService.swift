import Foundation

actor ClaudeAPIService {
    struct GeneratedContent {
        let affirmations: [String]
        let closing: String
    }

    enum APIError: Error, LocalizedError {
        case noAPIKey
        case invalidResponse
        case httpError(Int)
        case decodingError
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "No API key configured"
            case .invalidResponse: return "Invalid response from API"
            case .httpError(let code): return "HTTP error: \(code)"
            case .decodingError: return "Failed to decode response"
            case .networkError(let error): return "Network error: \(error.localizedDescription)"
            }
        }
    }

    func generateAffirmations(
        name: String,
        goals: String,
        categories: [String],
        recentGratitude: [String],
        recentIntentions: [String],
        count: Int
    ) async throws -> GeneratedContent {
        guard let apiKey = APIKeyConfiguration.getAPIKey(), !apiKey.isEmpty else {
            throw APIError.noAPIKey
        }

        var contextParts: [String] = []
        contextParts.append("User name: \(name)")
        if !goals.isEmpty {
            contextParts.append("Personal goals: \(goals)")
        }
        if !categories.isEmpty {
            contextParts.append("Focus areas: \(categories.joined(separator: ", "))")
        }
        if !recentGratitude.isEmpty {
            contextParts.append("Recent gratitude: \(recentGratitude.joined(separator: "; "))")
        }
        if !recentIntentions.isEmpty {
            contextParts.append("Recent intentions: \(recentIntentions.joined(separator: "; "))")
        }

        let systemPrompt = """
        You are a warm, encouraging affirmation generator. Create personalized morning affirmations.
        Each affirmation should be 1-2 sentences, present tense, positive, and directly relevant to the user's goals.
        Vary your style daily. Be specific, not generic.
        Also generate a short closing message (5-10 words) to end the morning session.

        Respond ONLY with valid JSON in this format:
        {"affirmations": ["...", "..."], "closing": "..."}
        """

        let userMessage = """
        Generate \(count) personalized morning affirmations.
        \(contextParts.joined(separator: "\n"))
        """

        let body: [String: Any] = [
            "model": AppConstants.apiModel,
            "max_tokens": AppConstants.maxTokens,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        var request = URLRequest(url: URL(string: AppConstants.apiURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(AppConstants.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) : (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        // Parse Claude response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw APIError.invalidResponse
        }

        // Extract JSON from response text
        guard let jsonData = text.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let affirmations = parsed["affirmations"] as? [String],
              let closing = parsed["closing"] as? String else {
            throw APIError.decodingError
        }

        return GeneratedContent(affirmations: affirmations, closing: closing)
    }
}
