import Foundation
import SwiftUI

class UserService: ObservableObject {
    @Published var profile: UserProfile = .empty
    @Published var isLoggedIn: Bool = false

    private let profileKey = "userProfile"

    init() {
        loadProfile()
    }

    func saveProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = profile
            self.isLoggedIn = true
        }
    }

    func completeOnboarding(profile: UserProfile) {
        self.profile = profile
        self.isLoggedIn = true
        saveProfile()
    }

    func updateStreak() {
        profile.streakDays += 1
        saveProfile()
    }
}
