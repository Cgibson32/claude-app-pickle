import AVFoundation

@MainActor @Observable
final class VoicePreviewService: NSObject, AVAudioPlayerDelegate {
    private let cloudTTS = ElevenLabsTTSService()
    private var audioPlayer: AVAudioPlayer?
    private var playerContinuation: CheckedContinuation<Void, Never>?
    private var sessionConfigured = false

    var voice: ElevenLabsTTSService.Voice = .rachel
    var lastError: String?

    func preview(text: String) async {
        lastError = nil
        configureSessionIfNeeded()

        guard APIKeyConfiguration.elevenLabsKey != nil else {
            lastError = "No ElevenLabs API key. Add ELEVENLABS_API_KEY in Codemagic."
            DiagnosticsLog.shared.log("preview", "no ElevenLabs key")
            return
        }

        do {
            DiagnosticsLog.shared.log("preview", "synthesizing \(voice.displayName)")
            let data = try await cloudTTS.synthesize(text: text, voice: voice)
            DiagnosticsLog.shared.log("preview", "got \(data.count) bytes, playing")
            await playAudioData(data)
        } catch {
            lastError = "Preview failed: \(error.localizedDescription)"
            DiagnosticsLog.shared.log("preview", "failed: \(error.localizedDescription)")
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
            player.volume = 1.0
            audioPlayer = player
            guard player.prepareToPlay(), player.play() else {
                lastError = "Audio player refused to play"
                DiagnosticsLog.shared.log("preview", "play() returned false")
                audioPlayer = nil
                return
            }
        } catch {
            lastError = "Audio init failed"
            DiagnosticsLog.shared.log("preview", "AVAudioPlayer init: \(error.localizedDescription)")
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
            self.lastError = "Decode error"
            self.audioPlayer = nil
            if let c = self.playerContinuation {
                self.playerContinuation = nil
                c.resume()
            }
        }
    }

    // MARK: - Session

    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
            sessionConfigured = true
        } catch {
            DiagnosticsLog.shared.log("preview", "audio session: \(error.localizedDescription)")
        }
    }
}
