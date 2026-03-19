import AVFoundation

@Observable
class AudioService {
    static let shared = AudioService()

    var isPlaying = false

    private var audioPlayer: AVAudioPlayer?

    private var isSessionConfigured = false

    private init() {}

    func playSound(named name: String) {
        if !isSessionConfigured {
            configureAudioSession()
            isSessionConfigured = true
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf") else {
            print("Sound file '\(name).caf' not found in bundle")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play sound: \(error)")
        }
    }

    func previewSound(named name: String) {
        stop()
        playSound(named: name)

        // Stop preview after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.stop()
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}
