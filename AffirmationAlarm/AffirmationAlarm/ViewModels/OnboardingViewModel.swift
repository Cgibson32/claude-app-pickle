import SwiftUI
import SwiftData

@Observable
class OnboardingViewModel {
    var currentStep = 0
    var name = ""
    var freeformGoals = ""
    var selectedCategories: Set<GoalCategory> = []
    var alarmTime = Calendar.current.date(from: DateComponents(hour: 6, minute: 30)) ?? Date()
    var selectedDays: Set<Int> = [2, 3, 4, 5, 6] // Mon-Fri
    var selectedSound = "alarm_gentle"

    let totalSteps = 4

    func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        }
    }

    func previousStep() {
        if currentStep > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep -= 1
            }
        }
    }

    func completeOnboarding(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(descriptor).first else { return }

        profile.name = name.trimmingCharacters(in: .whitespaces)
        profile.freeformGoals = freeformGoals.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.selectedCategories = selectedCategories.map(\.rawValue)
        profile.hasCompletedOnboarding = true

        // Create the first alarm
        let calendar = Calendar.current
        let alarm = Alarm(
            hour: calendar.component(.hour, from: alarmTime),
            minute: calendar.component(.minute, from: alarmTime),
            repeatDays: Array(selectedDays),
            isEnabled: true,
            soundName: selectedSound,
            label: "Morning Affirmations"
        )
        modelContext.insert(alarm)

        try? modelContext.save()

        // Schedule the alarm notifications
        AlarmSchedulingService.shared.scheduleAlarm(alarm)

        // Request notification permissions
        AlarmSchedulingService.shared.requestPermission { _ in }

        // Trigger initial affirmation cache
        Task {
            await AffirmationCacheService.shared.prefetchIfNeeded(
                modelContext: modelContext,
                profile: profile
            )
        }
    }
}
