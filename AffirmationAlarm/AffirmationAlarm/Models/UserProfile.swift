import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String = ""
    var freeformGoals: String = ""
    var hasCompletedOnboarding: Bool = false

    // Stored as JSON to avoid iOS 17.0-17.2 SwiftData array bug
    var selectedCategoriesData: String = "[]"

    var selectedCategories: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: Data(selectedCategoriesData.utf8))) ?? []
        }
        set {
            selectedCategoriesData = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    var speechRate: Float = 0.42
    var speechPitch: Float = 0.85
    var ttsEnabled: Bool = true
    var alarmSoundDuration: Float = 10
    var affirmationCount: Int = 3
    var createdAt: Date = Date.now

    var eveningReflectionEnabled: Bool = false
    var eveningReflectionHour: Int = 20
    var eveningReflectionMinute: Int = 0

    init() {}
}
