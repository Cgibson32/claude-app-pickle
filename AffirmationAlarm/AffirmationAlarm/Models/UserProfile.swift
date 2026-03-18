import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var freeformGoals: String
    var selectedCategories: [String]
    var hasCompletedOnboarding: Bool
    var speechRate: Float
    var speechPitch: Float
    var ttsEnabled: Bool
    var createdAt: Date

    init(
        name: String = "",
        freeformGoals: String = "",
        selectedCategories: [String] = [],
        hasCompletedOnboarding: Bool = false,
        speechRate: Float = 0.42,
        speechPitch: Float = 0.85,
        ttsEnabled: Bool = true,
        createdAt: Date = .now
    ) {
        self.name = name
        self.freeformGoals = freeformGoals
        self.selectedCategories = selectedCategories
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.speechRate = speechRate
        self.speechPitch = speechPitch
        self.ttsEnabled = ttsEnabled
        self.createdAt = createdAt
    }
}
