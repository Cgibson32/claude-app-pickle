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

@MainActor @Observable
class AffirmationSequenceViewModel {
    var phase: SequencePhase = .loading
    var affirmations: [Affirmation] = []
    var closingMessage: String = "Have a wonderful day"
    var error: String?
    var streakInfo: StreakService.StreakInfo?

    private let cacheService = AffirmationCacheService()
    private let speechService = SpeechService()
    private var alarmSoundName = "alarm_gentle"

    @MainActor
    func start(profile: UserProfile, modelContext: ModelContext) async {
        phase = .loading

        // Use the user's selected alarm sound
        if let alarm = (try? modelContext.fetch(FetchDescriptor<Alarm>()))?.first {
            alarmSoundName = alarm.soundName
        }

        // Match the in-app spoken voice to the user's chosen TTS voice so
        // the sequence sounds like the same person who spoke the pre-rendered
        // alarm audio.
        speechService.voice = OpenAITTSService.Voice(rawValue: profile.ttsVoice) ?? .nova

        do {
            let (affs, closing) = try await cacheService.fetchOrGenerate(for: profile, modelContext: modelContext)
            affirmations = affs
            if let closing { closingMessage = closing.message }
        } catch {
            // Use fallback affirmations if API fails. Cycle the hardcoded
            // pool up to the user's configured `affirmationCount` so the
            // sequence length matches their expectation even offline.
            let pool = [
                "Today I choose to be confident and kind",
                "I am worthy of all the good things coming my way",
                "I embrace this new day with gratitude and purpose",
                "I am grounded, present, and open to what today brings",
                "Every breath brings me closer to who I am becoming",
                "I carry calm and strength with me wherever I go"
            ]
            let count = max(1, profile.affirmationCount)
            affirmations = (0..<count).map { i in
                Affirmation(text: pool[i % pool.count], generatedFor: Date())
            }
            self.error = error.localizedDescription
        }

        // Build the full set of spoken lines and pre-fetch audio while the
        // alarm sound is playing, so each phase transition feels instant.
        // Trim the name so an empty or whitespace-only profile doesn't
        // render as "Good morning, ." with a dangling comma.
        let trimmedName = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let greetingText = trimmedName.isEmpty
            ? "Good morning. Let's start your day with intention."
            : "Good morning, \(trimmedName). Let's start your day with intention."
        let breathingText = "Let's take a deep breath together. Breathe in slowly... and release."
        let allSpokenTexts: [String] = {
            var texts = [greetingText]
            texts.append(contentsOf: affirmations.map(\.text))
            texts.append(breathingText)
            texts.append(closingMessage)
            return texts
        }()

        // Kick off prefetch in parallel with the alarm sound.
        let prefetchTask = Task { [speechService] in
            if profile.ttsEnabled {
                await speechService.prefetch(texts: allSpokenTexts)
            }
        }

        // Sequence flow
        await playPhase(.alarmSound, duration: TimeInterval(profile.alarmSoundDuration))
        AudioService.shared.stop()

        // Wait for prefetch (should already be done by now in most cases).
        await prefetchTask.value

        withAnimation(AppTheme.bouncy) { phase = .greeting }
        if profile.ttsEnabled {
            await speechService.speakAndWait(text: greetingText)
        } else {
            try? await Task.sleep(for: .seconds(2.5))
        }

        for i in 0..<affirmations.count {
            withAnimation(AppTheme.bouncy) { phase = .affirmation(i) }

            if profile.ttsEnabled {
                await speechService.speakAndWait(text: affirmations[i].text)
                try? await Task.sleep(for: .milliseconds(800))
            } else {
                try? await Task.sleep(for: .seconds(4))
            }
            affirmations[i].wasSpoken = true
        }

        // Breathing phase: speak the guide once at the start, then let the
        // animation continue for the remainder of the 12-second window.
        withAnimation(AppTheme.bouncy) { phase = .breathing }
        let breathingStart = Date()
        if profile.ttsEnabled {
            await speechService.speakAndWait(text: breathingText)
        }
        let elapsed = Date().timeIntervalSince(breathingStart)
        let remaining = max(0, 12.0 - elapsed)
        try? await Task.sleep(for: .seconds(remaining))

        withAnimation(AppTheme.bouncy) { phase = .closing }
        if profile.ttsEnabled {
            await speechService.speakAndWait(text: closingMessage)
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
            AudioService.shared.playSound(named: alarmSoundName, duration: duration)
        }

        try? await Task.sleep(for: .seconds(duration))
    }
}
