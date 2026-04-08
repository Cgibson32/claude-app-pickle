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

    /// OpenAI's supported voices, ranked roughly from warmest/most conversational
    /// (nova, shimmer) to the more clinical options. Kept as a string-backed
    /// enum so the raw value can be passed straight to the API and persisted on
    /// `UserProfile.ttsVoice` without extra mapping.
    enum Voice: String, CaseIterable, Sendable {
        case nova        // Warm, conversational (default)
        case shimmer     // Soft, gentle
        case fable       // British, expressive
        case alloy       // Neutral, balanced
        case echo        // Clear, male
        case onyx        // Deep, male

        var displayName: String {
            switch self {
            case .nova: return "Nova"
            case .shimmer: return "Shimmer"
            case .fable: return "Fable"
            case .alloy: return "Alloy"
            case .echo: return "Echo"
            case .onyx: return "Onyx"
            }
        }

        var tagline: String {
            switch self {
            case .nova: return "Warm & conversational"
            case .shimmer: return "Soft & gentle"
            case .fable: return "British & expressive"
            case .alloy: return "Neutral & balanced"
            case .echo: return "Clear & grounded"
            case .onyx: return "Deep & reassuring"
            }
        }
    }

    /// Audio formats OpenAI's `response_format` accepts. `mp3` is the smallest
    /// and what the in-app speech playback uses. `wav` is Linear PCM inside a
    /// WAV container — the only format we can drop straight into
    /// `Library/Sounds/` and hand to AlarmKit as an alarm-fire sound without
    /// transcoding.
    enum Format: String, Sendable {
        case mp3
        case wav
    }

    /// In-memory cache keyed by (text, voice, format). Audio is small
    /// (~20-60KB per sentence) and the session speaks the same set of ~5-7
    /// phrases, so memory pressure is negligible.
    private var cache: [String: Data] = [:]

    /// Fetches audio for the given text. Returns cached data on repeat calls
    /// for the same (text, voice, format) triple.
    func synthesize(
        text: String,
        voice: Voice = .nova,
        format: Format = .mp3
    ) async throws -> Data {
        let cacheKey = "\(voice.rawValue)|\(format.rawValue)|\(text)"
        if let cached = cache[cacheKey] {
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
            "voice": voice.rawValue,
            "input": text,
            "response_format": format.rawValue,
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

        cache[cacheKey] = data
        return data
    }

    /// Concurrently pre-fetch multiple texts, ignoring individual failures.
    /// Returns a dictionary of text → audio data for items that succeeded.
    /// Always uses MP3 at the default voice — callers that need a specific
    /// voice should hit `synthesize(text:voice:format:)` directly.
    func prefetch(_ texts: [String], voice: Voice = .nova) async -> [String: Data] {
        await withTaskGroup(of: (String, Data?).self) { group in
            for text in texts {
                group.addTask { [weak self] in
                    guard let self else { return (text, nil) }
                    let data = try? await self.synthesize(text: text, voice: voice, format: .mp3)
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
