import Foundation

/// Synthesizes spoken audio via OpenAI's `/audio/speech` endpoint.
///
/// Keeps an in-memory cache keyed by `(voice, format, text)` so repeat
/// requests within a session don't burn API credits. A typical session
/// speaks ~5–7 distinct phrases, each ~20–60 KB, so memory pressure is
/// negligible.
@MainActor
final class OpenAITTSService {

    // MARK: - Types

    enum TTSError: Error, LocalizedError {
        case noAPIKey
        case badURL
        case network(any Error)
        case httpStatus(Int, body: String)
        case emptyBody

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "No OpenAI API key configured"
            case .badURL: return "Invalid OpenAI TTS URL"
            case .network(let error): return "Network error: \(error.localizedDescription)"
            case .httpStatus(let code, let body): return "OpenAI TTS HTTP \(code): \(body)"
            case .emptyBody: return "Empty response body from OpenAI TTS"
            }
        }
    }

    /// Supported voices, ranked roughly from warmest (nova) to most
    /// clinical (onyx). Raw values match OpenAI's API names and are also
    /// persisted on `UserProfile.ttsVoice`, so callers can round-trip
    /// without additional mapping.
    enum Voice: String, CaseIterable, Sendable {
        case nova
        case shimmer
        case fable
        case alloy
        case echo
        case onyx

        var displayName: String {
            switch self {
            case .nova: "Nova"
            case .shimmer: "Shimmer"
            case .fable: "Fable"
            case .alloy: "Alloy"
            case .echo: "Echo"
            case .onyx: "Onyx"
            }
        }

        var tagline: String {
            switch self {
            case .nova: "Warm & conversational"
            case .shimmer: "Soft & gentle"
            case .fable: "British & expressive"
            case .alloy: "Neutral & balanced"
            case .echo: "Clear & grounded"
            case .onyx: "Deep & reassuring"
            }
        }
    }

    /// Audio formats the API accepts. `mp3` is the smallest and plays
    /// natively on `AVAudioPlayer`. `wav` is Linear PCM inside a WAV
    /// container — the format `MorningAudioRenderer` rewraps into CAF
    /// for AlarmKit `.named()` consumption.
    enum Format: String, Sendable {
        case mp3
        case wav
    }

    // MARK: - State

    private struct CacheKey: Hashable {
        let voice: Voice
        let format: Format
        let text: String
    }

    private var cache: [CacheKey: Data] = [:]

    // MARK: - Public API

    /// Synthesize audio for the given text. Returns cached bytes on
    /// repeat calls for the same `(voice, format, text)` triple.
    func synthesize(
        text: String,
        voice: Voice = .nova,
        format: Format = .mp3
    ) async throws -> Data {
        let key = CacheKey(voice: voice, format: format, text: text)
        if let hit = cache[key] { return hit }

        guard let apiKey = APIKeyConfiguration.openAIKey, !apiKey.isEmpty else {
            throw TTSError.noAPIKey
        }
        guard let url = URL(string: AppConstants.openAITTSURL) else {
            throw TTSError.badURL
        }

        let payload = SpeechRequest(
            model: "tts-1-hd",
            voice: voice.rawValue,
            input: text,
            responseFormat: format.rawValue,
            speed: 0.95
        )
        let request = try makeURLRequest(url: url, apiKey: apiKey, payload: payload)
        let data = try await perform(request)

        cache[key] = data
        return data
    }

    /// Pre-fetch many texts concurrently, ignoring individual failures.
    /// Returns `text → audio` for entries that succeeded so the caller
    /// can fall back to in-session synthesis or local TTS on misses.
    ///
    /// Always uses MP3; callers needing WAV should call `synthesize`
    /// directly (WAV pre-fetching isn't a current use case).
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
                if let data { results[text] = data }
            }
            return results
        }
    }

    func clearCache() {
        cache.removeAll()
    }

    // MARK: - Wire types

    private struct SpeechRequest: Encodable {
        let model: String
        let voice: String
        let input: String
        let responseFormat: String
        let speed: Double

        enum CodingKeys: String, CodingKey {
            case model, voice, input, speed
            case responseFormat = "response_format"
        }
    }

    // MARK: - Networking primitives

    private func makeURLRequest(
        url: URL,
        apiKey: String,
        payload: SpeechRequest
    ) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(payload)
        return request
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw TTSError.network(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw TTSError.httpStatus(-1, body: "no HTTP response")
        }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw TTSError.httpStatus(http.statusCode, body: body)
        }
        guard !data.isEmpty else {
            throw TTSError.emptyBody
        }
        return data
    }
}
