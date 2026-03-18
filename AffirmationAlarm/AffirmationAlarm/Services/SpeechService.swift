import AVFoundation

struct SpeechItem {
    let text: String
    let postDelay: TimeInterval
}

@Observable
class SpeechService: NSObject {
    static let shared = SpeechService()

    var isSpeaking = false
    var currentItemIndex = 0
    var isComplete = false

    private let synthesizer = AVSpeechSynthesizer()
    private var items: [SpeechItem] = []
    private var rate: Float = AppConstants.defaultSpeechRate
    private var pitch: Float = AppConstants.defaultSpeechPitch
    private var volume: Float = AppConstants.defaultSpeechVolume
    private var onItemStarted: ((Int) -> Void)?
    private var onComplete: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func configure(rate: Float, pitch: Float) {
        self.rate = rate
        self.pitch = pitch
    }

    func speakSequence(
        items: [SpeechItem],
        onItemStarted: ((Int) -> Void)? = nil,
        onComplete: (() -> Void)? = nil
    ) {
        stop()
        self.items = items
        self.currentItemIndex = 0
        self.isComplete = false
        self.isSpeaking = true
        self.onItemStarted = onItemStarted
        self.onComplete = onComplete

        speakCurrentItem()
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        items = []
        currentItemIndex = 0
    }

    // MARK: - Private

    private func speakCurrentItem() {
        guard currentItemIndex < items.count else {
            isSpeaking = false
            isComplete = true
            onComplete?()
            return
        }

        let item = items[currentItemIndex]
        onItemStarted?(currentItemIndex)

        let utterance = AVSpeechUtterance(string: item.text)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0

        synthesizer.speak(utterance)
    }

    private func advanceToNextItem() {
        let postDelay = items[currentItemIndex].postDelay
        currentItemIndex += 1

        if postDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + postDelay) { [weak self] in
                self?.speakCurrentItem()
            }
        } else {
            speakCurrentItem()
        }
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.advanceToNextItem()
        }
    }
}
