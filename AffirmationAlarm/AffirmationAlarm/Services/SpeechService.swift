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
class SpeechService: NSObject, @preconcurrency AVSpeechSynthesizerDelegate, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    private var items: [SpeechItem] = []
    private var currentIndex = 0
    private var completion: (() -> Void)?
    var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(items: [SpeechItem], rate: Float = 0.42, pitch: Float = 0.85, completion: @escaping () -> Void) {
        self.items = items
        self.currentIndex = 0
        self.completion = completion
        self.isSpeaking = true
        speakNext(rate: rate, pitch: pitch)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        items = []
        completion = nil
    }

    private func speakNext(rate: Float, pitch: Float) {
        guard currentIndex < items.count else {
            isSpeaking = false
            completion?()
            return
        }

        let item = items[currentIndex]
        let utterance = AVSpeechUtterance(string: item.text)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = item.postDelay
        synthesizer.speak(utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        currentIndex += 1
        let rate = utterance.rate
        let pitch = utterance.pitchMultiplier
        speakNext(rate: rate, pitch: pitch)
    }
}
