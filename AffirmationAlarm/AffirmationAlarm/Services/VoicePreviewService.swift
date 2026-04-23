import AVFoundation

/// Plays a short voice sample for the user via OpenAI TTS. The only
/// consumer is `SpeechSettingsView` so the user can hear each voice
/// before picking one — the alarm-time ritual itself is pre-rendered by
/// `MorningAudioRenderer` and played by AlarmKit, never by this service.
///
/// Responsibilities, kept deliberately narrow:
/// - Synthesize the sample via `OpenAITTSService` (cache persists across
///   taps for instant replay).
/// - Play the returned MP3 via a transient `AVAudioPlayer`.
/// - `await preview(...)` returns when playback finishes or is stopped.
/// - `stop()` cancels in-flight playback.
///
/// No `AVSpeechSynthesizer` fallback: if OpenAI fails, `preview` returns
/// silently — the user can tap again. There is no alarm-critical path
/// here, so offline fallback isn't worth the complexity.
@MainActor @Observable
final class VoicePreviewService: NSObject, AVAudioPlayerDelegate {
    private let cloudTTS = ElevenLabsTTSService()
    private var audioPlayer: AVAudioPlayer?
    private var playerContinuation: CheckedContinuation<Void, Never>?
    private var sessionConfigured = false

    var voice: ElevenLabsTTSService.Voice = .rachel

    /// Synthesize `text` with the current `voice` and play it. Returns
    /// when playback finishes, is interrupted by `stop()`, or on any
    /// synthesis/playback failure.
    func preview(text: String) async {
        configureSessionIfNeeded()
        do {
            let data = try await cloudTTS.synthesize(text: text, voice: voice)
            await playAudioData(data)
        } catch {
            // Preview is best-effort; caller decides UI state.
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        if let c = playerContinuation {
            playerContinuation = nil
            c.resume()
        }
    }

    // MARK: - Playback

    private func playAudioData(_ data: Data) async {
        do {
            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            audioPlayer = player
            guard player.play() else {
                audioPlayer = nil
                return
            }
        } catch {
            return
        }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            playerContinuation = continuation
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.audioPlayer = nil
            if let c = self.playerContinuation {
                self.playerContinuation = nil
                c.resume()
            }
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.audioPlayer = nil
            if let c = self.playerContinuation {
                self.playerContinuation = nil
                c.resume()
            }
        }
    }

    // MARK: - Session

    /// Lazy `.playback`/`.spokenAudio` session so the preview is audible
    /// even if the user opens Voice Settings as their first interaction.
    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
            sessionConfigured = true
        } catch {
            // Best-effort; failure just means the preview might be quieter.
        }
    }
}
