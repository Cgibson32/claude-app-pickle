import SwiftUI
import SwiftData

enum SequencePhase: Equatable {
    case loading
    case alarmSound
    case greeting
    case affirmation(index: Int)
    case breathing
    case gratitude
    case closing
    case intention
    case complete
}

@Observable
class AffirmationSequenceViewModel {
    var phase: SequencePhase = .loading
    var affirmations: [String] = []
    var userName: String = ""
    var closingMessage: String = "Have a wonderful day"
    var alarmSoundName: String = "alarm_gentle"
    var alarmSoundDuration: TimeInterval = 10
    var gratitudeText: String = ""
    var intentionText: String = ""
    var streakCount: Int = 0

    private let speechService = SpeechService.shared
    private let audioService = AudioService.shared
    private var modelContext: ModelContext?

    func loadAndStart(modelContext: ModelContext) {
        self.modelContext = modelContext

        // Load user profile
        var maxCount = AppConstants.defaultAffirmationCount
        let profileDescriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(profileDescriptor).first {
            userName = profile.name
            alarmSoundDuration = TimeInterval(profile.alarmSoundDuration)
            maxCount = profile.affirmationCount
            speechService.configure(rate: profile.speechRate, pitch: profile.speechPitch)
        }

        // Load alarm sound from the most recent enabled alarm
        let alarmDescriptor = FetchDescriptor<Alarm>(
            sortBy: [SortDescriptor(\Alarm.hour), SortDescriptor(\Alarm.minute)]
        )
        if let alarm = (try? modelContext.fetch(alarmDescriptor))?.first(where: \.isEnabled) {
            alarmSoundName = alarm.soundName
        }

        // Load favorited affirmations first (these take priority)
        let favorites = AffirmationCacheService.shared.getFavoritedAffirmations(modelContext: modelContext)
        let favoritedTexts = Set(favorites.map(\.text))

        // Load today's generated affirmations
        let cachedAffirmations = AffirmationCacheService.shared.getLatestAffirmations(modelContext: modelContext)

        if cachedAffirmations.isEmpty && favorites.isEmpty {
            affirmations = [
                "I am worthy of all the good things coming my way today.",
                "I trust in my ability to create the life I desire.",
                "I radiate confidence, positivity, and strength."
            ]
        } else {
            // Favorites first, then fill remaining slots with generated ones
            var combined = Array(favoritedTexts)
            for affirmation in cachedAffirmations {
                guard combined.count < maxCount else { break }
                if !favoritedTexts.contains(affirmation.text) {
                    combined.append(affirmation.text)
                }
            }
            affirmations = Array(combined.prefix(maxCount))
        }

        // Load dynamic closing message
        if let cached = AffirmationCacheService.shared.getClosingMessage(for: Date(), modelContext: modelContext) {
            closingMessage = cached
        }

        startAlarmSound()
    }

    func startAlarmSound() {
        phase = .alarmSound
        audioService.playSound(named: alarmSoundName)

        // Play alarm sound, then transition to affirmation sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + alarmSoundDuration) { [weak self] in
            self?.audioService.stop()
            self?.startSequence()
        }
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

        // Gratitude prompt
        speechItems.append(SpeechItem(
            text: "What are you grateful for today?",
            postDelay: AppConstants.gratitudePostDelay
        ))

        // Closing — dynamic, AI-generated send-off
        speechItems.append(SpeechItem(
            text: "\(closingMessage), \(userName)",
            postDelay: 1.5
        ))

        // Intention prompt
        speechItems.append(SpeechItem(
            text: "What is your one intention for today?",
            postDelay: AppConstants.intentionPostDelay
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
                    self?.onSequenceComplete()
                }
            }
        )
    }

    func stopSpeech() {
        audioService.stop()
        speechService.stop()
    }

    func saveGratitude(modelContext: ModelContext) {
        let trimmed = gratitudeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let entry = GratitudeEntry(text: trimmed)
        modelContext.insert(entry)
        try? modelContext.save()
    }

    func saveIntention(modelContext: ModelContext) {
        let trimmed = intentionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let intention = DailyIntention(text: trimmed)
        modelContext.insert(intention)
        try? modelContext.save()
    }

    // MARK: - Private

    private func onSequenceComplete() {
        // Record streak completion
        if let modelContext {
            StreakService.shared.recordCompletion(modelContext: modelContext)
            streakCount = StreakService.shared.currentStreak(modelContext: modelContext)
            saveGratitude(modelContext: modelContext)
            saveIntention(modelContext: modelContext)
        }

        withAnimation(.easeInOut(duration: 0.5)) {
            phase = .complete
        }
    }

    private func updatePhase(for speechIndex: Int) {
        let n = affirmations.count
        withAnimation(.easeInOut(duration: 0.5)) {
            if speechIndex == 0 {
                phase = .greeting
            } else if speechIndex <= n {
                phase = .affirmation(index: speechIndex - 1)
            } else if speechIndex == n + 1 {
                phase = .breathing
            } else if speechIndex == n + 2 {
                phase = .gratitude
            } else if speechIndex == n + 3 {
                phase = .closing
            } else if speechIndex == n + 4 {
                phase = .intention
            }
        }
    }
}
