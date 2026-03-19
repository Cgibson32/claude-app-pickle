import AVFoundation

@Observable
class AudioService {
    static let shared = AudioService()
    private var player: AVAudioPlayer?
    private var sessionConfigured = false

    private init() {}

    func playSound(named name: String, duration: TimeInterval = 10) {
        configureSessionIfNeeded()

        guard let url = Bundle.main.url(forResource: name, withExtension: "caf") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.play()

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                self?.stop()
            }
        } catch {
            // Silently fail — sound is nice-to-have, not critical
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }

    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            sessionConfigured = true
        } catch {
            // Audio session config is best-effort
        }
    }
}
