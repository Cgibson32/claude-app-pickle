import Foundation

/// Synthesizes spoken audio via ElevenLabs' text-to-speech API.
/// High quality, natural-sounding voices with v3 audio tag support.
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
        case charlotte = "XB0fDUnXU5powFXDhCwa"   // default
        case om        = "ePiPWpzcHZrcqRzFrgQg"
        case clara     = "Qggl4bOxRMiqOwhPtVWT"
        case daniel    = "onwK4e9ZLuTAKqWW03F9"

        var displayName: String {
            switch self {
            case .charlotte: "Charlotte"
            case .om:        "Om"
            case .clara:     "Clara"
            case .daniel:    "Daniel"
            }
        }

        var tagline: String {
            switch self {
            case .charlotte: "Warm & grounded"
            case .om:        "Calm & centered"
            case .clara:     "Soft & encouraging"
            case .daniel:    "Deep & authoritative"
            }
        }

        /// Default Eleven v3 audio tag that steers this voice's delivery
        /// toward a warm, motivational morning tone. Prepended to the
        /// script unless a per-call override is supplied. v3 tags are
        /// voice/context dependent — these are conservative, widely
        /// supported ones (warmly / calm / confident / gently).
        var defaultDeliveryTag: String {
            switch self {
            case .charlotte: "warmly"
            case .om:        "calm"
            case .clara:     "gently"
            case .daniel:    "confident"
            }
        }
    }

    // MARK: - State

    /// Eleven v3 — the most expressive model and the only one that
    /// honors inline audio tags ([warmly], [confident], …). The pool
    /// pre-renders audio well ahead of fire time, so v3's higher latency
    /// is a non-issue here. Single constant for easy revert if v3 access
    /// or cost ever becomes a problem (fall back to "eleven_turbo_v2_5").
    private static let modelID = "eleven_v3"

    private struct CacheKey: Hashable {
        let voice: Voice
        let text: String
        let delivery: String
    }

    private var cache: [CacheKey: Data] = [:]

    // MARK: - Public API

    /// Synthesize speech. `delivery` is an optional Eleven v3 audio tag
    /// (without brackets, e.g. "warmly", "confident", "excited") that
    /// steers tone. When nil, the voice's `defaultDeliveryTag` is used.
    /// Pass an empty string to send no tag at all.
    func synthesize(
        text: String,
        voice: Voice = .charlotte,
        delivery: String? = nil,
        format: String = "mp3_44100_128"
    ) async throws -> Data {
        let tag = delivery ?? voice.defaultDeliveryTag
        let key = CacheKey(voice: voice, text: text, delivery: tag)
        if let hit = cache[key] { return hit }

        guard let apiKey = APIKeyConfiguration.elevenLabsKey, !apiKey.isEmpty else {
            throw TTSError.noAPIKey
        }

        // output_format is a QUERY parameter, not a body field.
        let urlString = "https://api.elevenlabs.io/v1/text-to-speech/\(voice.rawValue)?output_format=\(format)"
        guard let url = URL(string: urlString) else {
            throw TTSError.badURL
        }

        // Prepend the audio tag so v3 opens in the intended tone and
        // carries that emotional context through the script.
        let taggedText = tag.isEmpty ? text : "[\(tag)] \(text)"

        let payload = SpeechRequest(
            text: taggedText,
            modelId: Self.modelID,
            // v3-appropriate: stability 0.5 ("Natural") is the balance
            // point where audio tags still meaningfully steer delivery
            // without the voice drifting. speaker boost on for presence.
            voiceSettings: VoiceSettings(
                stability: 0.5,
                similarityBoost: 0.8,
                useSpeakerBoost: true
            )
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
        let useSpeakerBoost: Bool

        enum CodingKeys: String, CodingKey {
            case stability
            case similarityBoost = "similarity_boost"
            case useSpeakerBoost = "use_speaker_boost"
        }
    }
}
