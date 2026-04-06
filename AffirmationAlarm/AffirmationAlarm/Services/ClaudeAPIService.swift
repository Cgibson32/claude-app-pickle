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

    struct RecentReflection: Sendable {
        let mood: Int
        let goodThing: String
        let gratitude: String
    }

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

        var contextParts: [String] = []
        contextParts.append("User name: \(name)")
        if !goals.isEmpty {
            contextParts.append("Personal goals (their own words): \(goals)")
        }
        if !categories.isEmpty {
            contextParts.append("Focus areas: \(categories.joined(separator: ", "))")
        }
        if !recentGratitude.isEmpty {
            contextParts.append("Recent gratitude notes: \(recentGratitude.joined(separator: "; "))")
        }
        if !recentIntentions.isEmpty {
            contextParts.append("Recent daily intentions: \(recentIntentions.joined(separator: "; "))")
        }
        if !recentReflections.isEmpty {
            let moodLabels = ["tough", "meh", "okay", "good", "amazing"]
            let reflectionLines = recentReflections.map { r -> String in
                let moodIdx = max(0, min(4, r.mood))
                return "mood=\(moodLabels[moodIdx]), highlight=\"\(r.goodThing)\", grateful for=\"\(r.gratitude)\""
            }
            contextParts.append("Recent evening reflections:\n- " + reflectionLines.joined(separator: "\n- "))
        }

        let systemPrompt = """
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

        let userMessage = """
        Generate \(count) personalized morning affirmations for this person, following every rule in your instructions.

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

        guard let url = URL(string: AppConstants.apiURL) else {
            throw APIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
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
