import Foundation
import SwiftUI

class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var name: String = ""
    @Published var experienceLevel: ExperienceLevel = .intermediate
    @Published var playFrequency: PlayFrequency = .threeToFour
    @Published var playPreference: PlayPreference = .doubles
    @Published var selectedStruggles: Set<Struggle> = []
    @Published var selectedTechnicalWeaknesses: Set<TechnicalSkill> = []
    @Published var selectedMentalWeaknesses: Set<MentalSkill> = []
    @Published var selectedGoals: Set<PlayerGoal> = []
    @Published var playerIdentity: String = ""
    @Published var selectedFrustrations: Set<MatchFrustration> = []

    let totalSteps = 12

    var progress: Double {
        Double(currentStep) / Double(totalSteps - 1)
    }

    func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = min(currentStep + 1, totalSteps - 1)
        }
    }

    func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = max(currentStep - 1, 0)
        }
    }

    func canProceed() -> Bool {
        switch currentStep {
        case 0, 1, 2: return true // Welcome, mission, growth
        case 3: return !name.isEmpty
        case 4: return true // experience level
        case 5: return true // frequency
        case 6: return !selectedStruggles.isEmpty
        case 7: return !selectedTechnicalWeaknesses.isEmpty
        case 8: return !selectedMentalWeaknesses.isEmpty
        case 9: return !selectedGoals.isEmpty
        case 10: return !selectedFrustrations.isEmpty
        case 11: return true // summary
        default: return true
        }
    }

    func buildProfile() -> UserProfile {
        UserProfile(
            id: UUID(),
            name: name,
            experienceLevel: experienceLevel,
            playFrequency: playFrequency,
            playPreference: playPreference,
            struggles: Array(selectedStruggles),
            technicalWeaknesses: Array(selectedTechnicalWeaknesses),
            mentalWeaknesses: Array(selectedMentalWeaknesses),
            goals: Array(selectedGoals),
            playerIdentity: playerIdentity,
            matchFrustrations: Array(selectedFrustrations),
            createdAt: Date(),
            streakDays: 0,
            journalStreak: 0,
            totalSessions: 0
        )
    }
}
