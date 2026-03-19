import SwiftUI
import SwiftData

enum SequencePhase: Equatable {
    case loading
    case alarmSound
    case greeting
    case affirmation(Int)
    case breathing
    case closing
    case complete
}

@Observable
class AffirmationSequenceViewModel {
    var phase: SequencePhase = .loading
    var affirmations: [Affirmation] = []
    var closingMessage: String = "Have a wonderful day"
    var error: String?
    var streakInfo: StreakService.StreakInfo?

    private let cacheService = AffirmationCacheService()
    private let speechService = SpeechService()

    @MainActor
    func start(profile: UserProfile, modelContext: ModelContext) async {
        phase = .loading

        do {
            let (affs, closing) = try await cacheService.fetchOrGenerate(for: profile, modelContext: modelContext)
            affirmations = affs
            if let closing { closingMessage = closing.message }
        } catch {
            // Use fallback affirmations if API fails
            affirmations = [
                Affirmation(text: "Today I choose to be confident and kind", generatedFor: Date()),
                Affirmation(text: "I am worthy of all the good things coming my way", generatedFor: Date()),
                Affirmation(text: "I embrace this new day with gratitude and purpose", generatedFor: Date())
            ]
            self.error = error.localizedDescription
        }

        // Sequence flow
        await playPhase(.alarmSound, duration: TimeInterval(profile.alarmSoundDuration))
        AudioService.shared.stop()

        await playPhase(.greeting, duration: 3.0)

        for i in 0..<affirmations.count {
            withAnimation(AppTheme.bouncy) { phase = .affirmation(i) }

            if profile.ttsEnabled {
                await speakAndWait(
                    text: affirmations[i].text,
                    rate: profile.speechRate,
                    pitch: profile.speechPitch
                )
            } else {
                try? await Task.sleep(for: .seconds(4))
            }
            affirmations[i].wasSpoken = true
        }

        await playPhase(.breathing, duration: 12.0)

        withAnimation(AppTheme.bouncy) { phase = .closing }
        if profile.ttsEnabled {
            await speakAndWait(text: closingMessage, rate: profile.speechRate, pitch: profile.speechPitch)
        }
        try? await Task.sleep(for: .seconds(2))

        // Record completion
        let completion = SequenceCompletion()
        modelContext.insert(completion)

        // Calculate streak
        let allCompletions = (try? modelContext.fetch(FetchDescriptor<SequenceCompletion>())) ?? []
        streakInfo = StreakService.calculate(completions: allCompletions)

        withAnimation(AppTheme.bouncy) { phase = .complete }
    }

    func skip() {
        AudioService.shared.stop()
        speechService.stop()
        withAnimation(AppTheme.bouncy) { phase = .complete }
    }

    private func playPhase(_ newPhase: SequencePhase, duration: TimeInterval) async {
        withAnimation(AppTheme.bouncy) { phase = newPhase }

        if newPhase == .alarmSound {
            AudioService.shared.playSound(named: "alarm_gentle", duration: duration)
        }

        try? await Task.sleep(for: .seconds(duration))
    }

    private func speakAndWait(text: String, rate: Float, pitch: Float) async {
        await withCheckedContinuation { continuation in
            speechService.speak(
                items: [SpeechItem(text)],
                rate: rate,
                pitch: pitch
            ) {
                continuation.resume()
            }
        }
    }
}
