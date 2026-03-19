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
    var alarmSoundDuration: Float
    var affirmationCount: Int
    var createdAt: Date
    var eveningReflectionEnabled: Bool
    var eveningReflectionHour: Int
    var eveningReflectionMinute: Int

    init(
        name: String = "",
        freeformGoals: String = "",
        selectedCategories: [String] = [],
        hasCompletedOnboarding: Bool = false,
        speechRate: Float = 0.42,
        speechPitch: Float = 0.85,
        ttsEnabled: Bool = true,
        alarmSoundDuration: Float = 10,
        affirmationCount: Int = 3,
        createdAt: Date = .now,
        eveningReflectionEnabled: Bool = false,
        eveningReflectionHour: Int = 20,
        eveningReflectionMinute: Int = 0
    ) {
        self.name = name
        self.freeformGoals = freeformGoals
        self.selectedCategories = selectedCategories
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.speechRate = speechRate
        self.speechPitch = speechPitch
        self.ttsEnabled = ttsEnabled
        self.alarmSoundDuration = alarmSoundDuration
        self.affirmationCount = affirmationCount
        self.createdAt = createdAt
        self.eveningReflectionEnabled = eveningReflectionEnabled
        self.eveningReflectionHour = eveningReflectionHour
        self.eveningReflectionMinute = eveningReflectionMinute
    }
}
