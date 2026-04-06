import Foundation

@MainActor
final class OpenAITTSService {
    enum TTSError: Error, LocalizedError {
        case noAPIKey
        case invalidResponse
        case httpError(Int, String)
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "No OpenAI API key configured"
            case .invalidResponse: return "Invalid response from OpenAI TTS"
            case .httpError(let code, let body): return "OpenAI TTS HTTP \(code): \(body)"
            case .networkError(let error): return "Network error: \(error.localizedDescription)"
            }
        }
    }

    /// In-memory cache keyed by input text. Audio is small (~20-60KB per sentence)
    /// and the session speaks the same set of ~5-7 phrases, so memory pressure is negligible.
    private var cache: [String: Data] = [:]

    /// Fetches MP3 audio for the given text. Returns cached data on repeat calls.
    func synthesize(text: String) async throws -> Data {
        if let cached = cache[text] {
            return cached
        }

        guard let apiKey = APIKeyConfiguration.openAIKey, !apiKey.isEmpty else {
            throw TTSError.noAPIKey
        }

        guard let url = URL(string: AppConstants.openAITTSURL) else {
            throw TTSError.invalidResponse
        }

        let body: [String: Any] = [
            "model": "tts-1-hd",
            "voice": "nova",
            "input": text,
            "response_format": "mp3",
            "speed": 0.95
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw TTSError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw TTSError.invalidResponse
        }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw TTSError.httpError(http.statusCode, body)
        }

        cache[text] = data
        return data
    }

    /// Concurrently pre-fetch multiple texts, ignoring individual failures.
    /// Returns a dictionary of text → audio data for items that succeeded.
    func prefetch(_ texts: [String]) async -> [String: Data] {
        await withTaskGroup(of: (String, Data?).self) { group in
            for text in texts {
                group.addTask { [weak self] in
                    guard let self else { return (text, nil) }
                    let data = try? await self.synthesize(text: text)
                    return (text, data)
                }
            }
            var results: [String: Data] = [:]
            for await (text, data) in group {
                if let data {
                    results[text] = data
                }
            }
            return results
        }
    }

    func clearCache() {
        cache.removeAll()
    }
}
