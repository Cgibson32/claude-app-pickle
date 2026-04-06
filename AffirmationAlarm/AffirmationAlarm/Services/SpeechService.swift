import AVFoundation

struct SpeechItem {
    let text: String
    let postDelay: TimeInterval

    init(_ text: String, postDelay: TimeInterval = 1.5) {
        self.text = text
        self.postDelay = postDelay
    }
}

@MainActor @Observable
class SpeechService: NSObject, @preconcurrency AVSpeechSynthesizerDelegate, @preconcurrency AVAudioPlayerDelegate, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    private let cloudTTS = OpenAITTSService()
    private var audioPlayer: AVAudioPlayer?

    private var items: [SpeechItem] = []
    private var currentIndex = 0
    private var completion: (() -> Void)?
    private var playerContinuation: CheckedContinuation<Void, Never>?
    private var fallbackContinuation: CheckedContinuation<Void, Never>?
    var isSpeaking = false

    /// Pre-fetched audio keyed by text. Populated by `prefetch(texts:)` during
    /// the loading phase so playback is instant later.
    private var prefetchedAudio: [String: Data] = [:]

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Prefetch

    /// Concurrently pre-fetch audio for every text the sequence will speak.
    /// Safe to call even when offline — failures are silently ignored and
    /// those texts will fall back to `AVSpeechSynthesizer` at playback time.
    func prefetch(texts: [String]) async {
        let results = await cloudTTS.prefetch(texts)
        prefetchedAudio.merge(results) { _, new in new }
    }

    func clearPrefetch() {
        prefetchedAudio.removeAll()
        cloudTTS.clearCache()
    }

    // MARK: - Public speaking API

    /// Speak one line and wait until playback finishes. Prefers the cloud
    /// (nova) voice; falls back to `AVSpeechSynthesizer` on any error so the
    /// user always hears something even when offline.
    func speakAndWait(text: String) async {
        isSpeaking = true
        defer { isSpeaking = false }

        // Try cloud: prefetched first, otherwise live fetch.
        let cloudData: Data? = {
            if let cached = prefetchedAudio[text] { return cached }
            return nil
        }()

        if let data = cloudData {
            if await playAudioData(data) { return }
        } else {
            do {
                let data = try await cloudTTS.synthesize(text: text)
                if await playAudioData(data) { return }
            } catch {
                // fall through to on-device fallback
            }
        }

        await speakFallback(text: text)
    }

    /// Legacy entry point used by old call sites. Delegates to `speakAndWait`
    /// for each item, ignoring the rate/pitch arguments (the cloud voice has
    /// its own tuning).
    func speak(items: [SpeechItem], rate: Float = 0.42, pitch: Float = 0.85, completion: @escaping () -> Void) {
        Task { @MainActor in
            for item in items {
                await self.speakAndWait(text: item.text)
                if item.postDelay > 0 {
                    try? await Task.sleep(for: .seconds(item.postDelay))
                }
            }
            completion()
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
        audioPlayer = nil
        if let c = playerContinuation { playerContinuation = nil; c.resume() }
        if let c = fallbackContinuation { fallbackContinuation = nil; c.resume() }
        isSpeaking = false
        items = []
        completion = nil
    }

    // MARK: - Cloud playback

    /// Plays MP3 data and awaits completion. Returns `true` on success,
    /// `false` if the player couldn't be initialized (caller should fall back).
    private func playAudioData(_ data: Data) async -> Bool {
        do {
            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            audioPlayer = player
            guard player.play() else {
                audioPlayer = nil
                return false
            }
        } catch {
            return false
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            playerContinuation = continuation
        }
        return true
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

    // MARK: - AVSpeechSynthesizer fallback

    private func speakFallback(text: String) async {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.42
        utterance.pitchMultiplier = 0.95
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.2

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            fallbackContinuation = continuation
            synthesizer.speak(utterance)
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if let c = fallbackContinuation {
            fallbackContinuation = nil
            c.resume()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        if let c = fallbackContinuation {
            fallbackContinuation = nil
            c.resume()
        }
    }
}
