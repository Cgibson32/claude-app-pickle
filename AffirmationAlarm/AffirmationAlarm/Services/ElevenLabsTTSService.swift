import Foundation

/// Synthesizes spoken audio via ElevenLabs' text-to-speech API.
/// Drop-in replacement for OpenAITTSService with higher quality,
/// more natural-sounding voices.
@MainActor
final class ElevenLabsTTSService {

    // MARK: - Types

    enum TTSError: Error, LocalizedError {
        case noAPIKey
        case badURL
        case network(any Error)
        case httpStatus(Int, body: String)
        case emptyBody

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "No ElevenLabs API key configured"
            case .badURL: return "Invalid ElevenLabs TTS URL"
            case .network(let error): return "Network error: \(error.localizedDescription)"
            case .httpStatus(let code, let body): return "ElevenLabs TTS HTTP \(code): \(body)"
            case .emptyBody: return "Empty response body from ElevenLabs TTS"
            }
        }
    }

    /// Curated voices that work well for morning affirmations —
    /// confident, warm, inspiring. Raw values are ElevenLabs voice IDs.
    enum Voice: String, CaseIterable, Sendable {
        case rachel = "21m00Tcm4TlvDq8ikWAM"
        case drew   = "29vD33N1CtxCmqQRPOHJ"
        case sarah  = "EXAVITQu4vr4xnSDxMaL"
        case matilda = "XrExE9yKIg1WjnnlVkGX"
        case brian  = "nPczCjzI2devNBz1zQrb"
        case daniel = "onwK4e9ZLuTAKqWW03F9"
        case lily   = "pFZP5JQG7iQjIQuC4Bku"
        case chris  = "iP95p4xoKVk53GoZ742B"

        var displayName: String {
            switch self {
            case .rachel: "Rachel"
            case .drew:   "Drew"
            case .sarah:  "Sarah"
            case .matilda: "Matilda"
            case .brian:  "Brian"
            case .daniel: "Daniel"
            case .lily:   "Lily"
            case .chris:  "Chris"
            }
        }

        var tagline: String {
            switch self {
            case .rachel: "Calm & confident"
            case .drew:   "Warm & assured"
            case .sarah:  "Soft & encouraging"
            case .matilda: "Warm & nurturing"
            case .brian:  "Deep & grounded"
            case .daniel: "Deep & authoritative"
            case .lily:   "Warm & British"
            case .chris:  "Casual & friendly"
            }
        }
    }

    // MARK: - State

    private struct CacheKey: Hashable {
        let voice: Voice
        let text: String
    }

    private var cache: [CacheKey: Data] = [:]

    // MARK: - Public API

    func synthesize(
        text: String,
        voice: Voice = .rachel,
        format: String = "mp3_44100_128"
    ) async throws -> Data {
        let key = CacheKey(voice: voice, text: text)
        if let hit = cache[key] { return hit }

        guard let apiKey = APIKeyConfiguration.elevenLabsKey, !apiKey.isEmpty else {
            throw TTSError.noAPIKey
        }

        // output_format is a QUERY parameter, not a body field.
        let urlString = "https://api.elevenlabs.io/v1/text-to-speech/\(voice.rawValue)?output_format=\(format)"
        guard let url = URL(string: urlString) else {
            throw TTSError.badURL
        }

        let payload = SpeechRequest(
            text: text,
            modelId: "eleven_turbo_v2_5",
            voiceSettings: VoiceSettings(stability: 0.6, similarityBoost: 0.75, style: 0.3)
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.httpBody = try JSONEncoder().encode(payload)

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
            let body = String(data: data.prefix(300), encoding: .utf8) ?? ""
            DiagnosticsLog.shared.log("tts", "ElevenLabs HTTP \(http.statusCode): \(body)")
            throw TTSError.httpStatus(http.statusCode, body: body)
        }
        guard !data.isEmpty else {
            throw TTSError.emptyBody
        }

        cache[key] = data
        return data
    }

    func clearCache() {
        cache.removeAll()
    }

    // MARK: - Wire types

    private struct SpeechRequest: Encodable {
        let text: String
        let modelId: String
        let voiceSettings: VoiceSettings

        enum CodingKeys: String, CodingKey {
            case text
            case modelId = "model_id"
            case voiceSettings = "voice_settings"
        }
    }

    private struct VoiceSettings: Encodable {
        let stability: Double
        let similarityBoost: Double
        let style: Double

        enum CodingKeys: String, CodingKey {
            case stability
            case similarityBoost = "similarity_boost"
            case style
        }
    }
}
