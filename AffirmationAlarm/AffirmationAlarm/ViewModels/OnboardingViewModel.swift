import SwiftUI
import SwiftData

@Observable
class OnboardingViewModel {
    var currentStep = 0
    var name = ""
    var goals = ""
    var selectedCategories: Set<GoalCategory> = []
    var affirmationCount = 3
    var eveningReflectionEnabled = false
    var eveningReflectionHour = 20
    var eveningReflectionMinute = 0
    var alarmHour = 6
    var alarmMinute = 30
    var alarmRepeatDays: Set<Int> = []
    var alarmSound = AppConstants.AlarmSound.gentle

    let totalSteps = 4

    var canAdvance: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 2:
            let trimmed = goals.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.isEmpty && !ProfanityFilter.containsProfanity(trimmed)
        case 3: return true
        default: return false
        }
    }

    func advance() {
        if currentStep < totalSteps - 1 {
            withAnimation(AppTheme.bouncy) {
                currentStep += 1
            }
        }
    }

    func goBack() {
        if currentStep > 0 {
            withAnimation(AppTheme.bouncy) {
                currentStep -= 1
            }
        }
    }

    @MainActor
    func completeOnboarding(modelContext: ModelContext) {
        let profiles = (try? modelContext.fetch(FetchDescriptor<UserProfile>())) ?? []
        let profile = profiles.first ?? UserProfile()
        if profiles.isEmpty {
            modelContext.insert(profile)
        }

        profile.name = name.trimmingCharacters(in: .whitespaces)
        profile.freeformGoals = goals
        profile.selectedCategories = selectedCategories.map(\.rawValue)
        profile.affirmationCount = affirmationCount
        profile.eveningReflectionEnabled = eveningReflectionEnabled
        profile.eveningReflectionHour = eveningReflectionHour
        profile.eveningReflectionMinute = eveningReflectionMinute

        if eveningReflectionEnabled {
            EveningReflectionSchedulingService.schedule(
                hour: eveningReflectionHour,
                minute: eveningReflectionMinute
            )
        }

        let alarm = Alarm(
            hour: alarmHour,
            minute: alarmMinute,
            repeatDays: Array(alarmRepeatDays),
            soundName: alarmSound.rawValue
        )
        modelContext.insert(alarm)
        try? modelContext.save()

        profile.hasCompletedOnboarding = true

        // Ask for AlarmKit authorization, pre-render the personalized
        // morning audio (greeting + affirmations in the user's chosen
        // voice), then schedule the alarm. Rendering first means the
        // scheduler picks up the fresh file on its very first
        // `scheduleAlarm` call — the user wakes up to the voice tomorrow
        // morning with no empty-first-day gap.
        //
        // The render takes ~5-10 seconds (Claude + OpenAI TTS round-trips)
        // during which the user is already on HomeView with an empty
        // `TodayAffirmationsCard`. We set an `isPreparingFirstMorning`
        // flag in UserDefaults so HomeView can show a "Preparing your
        // first morning ritual..." banner until the render completes.
        UserDefaults.standard.set(true, forKey: "isPreparingFirstMorning")
        Task { @MainActor in
            defer { UserDefaults.standard.set(false, forKey: "isPreparingFirstMorning") }
            _ = await AlarmKitScheduler.shared.requestPermission()
            _ = await MorningAudioRenderer.shared.refresh(
                for: alarm,
                profile: profile,
                modelContext: modelContext
            )
            AlarmKitScheduler.shared.scheduleAlarm(alarm)

            // Start background keep-alive so auto-play observer stays
            // alive when the app is backgrounded after onboarding.
            BackgroundKeepAlive.shared.start()
        }
    }
}
