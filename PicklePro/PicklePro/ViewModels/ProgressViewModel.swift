import Foundation
import SwiftUI

class ProgressViewModel: ObservableObject {
    @Published var progressData: ProgressData

    init() {
        self.progressData = ProgressData.example
    }

    var topSkills: [SkillProgress] {
        progressData.skillProgress.sorted { $0.progress > $1.progress }.prefix(3).map { $0 }
    }

    var improvingSkills: [SkillProgress] {
        progressData.skillProgress.filter { $0.trend == .improving }
    }

    var averageMoodScore: Double {
        guard !progressData.weeklyMoodTrend.isEmpty else { return 0 }
        let total = progressData.weeklyMoodTrend.reduce(0) { $0 + $1.score }
        return Double(total) / Double(progressData.weeklyMoodTrend.count)
    }
}
