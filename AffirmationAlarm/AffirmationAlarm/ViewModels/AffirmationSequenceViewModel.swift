import SwiftUI
import SwiftData

enum SequencePhase: Equatable {
    case loading
    case greeting
    case affirmation(index: Int)
    case breathing
    case closing
    case complete
}

@Observable
class AffirmationSequenceViewModel {
    var phase: SequencePhase = .loading
    var affirmations: [String] = []
    var userName: String = ""
    var closingMessage: String = "Have a wonderful day"

    private let speechService = SpeechService.shared

    func loadAndStart(modelContext: ModelContext) {
        // Load user profile
        let profileDescriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(profileDescriptor).first {
            userName = profile.name
            speechService.configure(rate: profile.speechRate, pitch: profile.speechPitch)
        }

        // Load favorited affirmations (these repeat until un-favorited)
        let favorites = AffirmationCacheService.shared.getFavoritedAffirmations(modelContext: modelContext)
        let favoritedTexts = Set(favorites.map(\.text))

        // Load today's generated affirmations
        let cachedAffirmations = AffirmationCacheService.shared.getLatestAffirmations(modelContext: modelContext)

        if cachedAffirmations.isEmpty && favorites.isEmpty {
            // Use fallback affirmations
            affirmations = [
                "I am worthy of all the good things coming my way today.",
                "I trust in my ability to create the life I desire.",
                "I radiate confidence, positivity, and strength."
            ]
        } else {
            // Start with favorited affirmations, then add today's (deduplicated)
            var combined = Array(favoritedTexts)
            for affirmation in cachedAffirmations {
                if !favoritedTexts.contains(affirmation.text) {
                    combined.append(affirmation.text)
                }
            }
            affirmations = combined
        }

        // Load dynamic closing message
        if let cached = AffirmationCacheService.shared.getClosingMessage(for: Date(), modelContext: modelContext) {
            closingMessage = cached
        }

        startSequence()
    }

    func startSequence() {
        var speechItems: [SpeechItem] = []

        // Greeting
        speechItems.append(SpeechItem(
            text: "Good Morning, \(userName)",
            postDelay: AppConstants.greetingPostDelay
        ))

        // Affirmations
        for affirmation in affirmations {
            speechItems.append(SpeechItem(
                text: affirmation,
                postDelay: AppConstants.affirmationPostDelay
            ))
        }

        // Breathing prompt
        speechItems.append(SpeechItem(
            text: "Now take a deep breath into your heart. You are worthy of everything you desire, \(userName).",
            postDelay: AppConstants.breathingPostDelay
        ))

        // Closing — dynamic, AI-generated send-off
        speechItems.append(SpeechItem(
            text: "\(closingMessage), \(userName)",
            postDelay: 0
        ))

        phase = .greeting

        speechService.speakSequence(
            items: speechItems,
            onItemStarted: { [weak self] index in
                DispatchQueue.main.async {
                    self?.updatePhase(for: index)
                }
            },
            onComplete: { [weak self] in
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self?.phase = .complete
                    }
                }
            }
        )
    }

    func stopSpeech() {
        speechService.stop()
    }

    private func updatePhase(for speechIndex: Int) {
        withAnimation(.easeInOut(duration: 0.5)) {
            if speechIndex == 0 {
                phase = .greeting
            } else if speechIndex <= affirmations.count {
                phase = .affirmation(index: speechIndex - 1)
            } else if speechIndex == affirmations.count + 1 {
                phase = .breathing
            } else {
                phase = .closing
            }
        }
    }
}
