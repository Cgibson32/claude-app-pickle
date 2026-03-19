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
    var alarmRepeatDays: Set<Int> = [2, 3, 4, 5, 6]
    var alarmSound = AppConstants.AlarmSound.gentle

    let totalSteps = 5

    var canAdvance: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return !selectedCategories.isEmpty
        case 3: return true
        case 4: return true
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

        let alarm = Alarm(
            hour: alarmHour,
            minute: alarmMinute,
            repeatDays: Array(alarmRepeatDays),
            soundName: alarmSound.rawValue
        )
        modelContext.insert(alarm)

        profile.hasCompletedOnboarding = true
    }
}
