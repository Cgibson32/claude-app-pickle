import Foundation
import SwiftUI

class SubscriptionService: ObservableObject {
    @Published var isPremium: Bool {
        didSet { UserDefaults.standard.set(isPremium, forKey: "isPremium") }
    }
    @Published var showPaywall: Bool = false

    init() {
        self.isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }

    func purchase(plan: SubscriptionPlan) {
        // In production, integrate StoreKit 2
        isPremium = true
    }

    func restorePurchases() {
        // In production, restore via StoreKit 2
    }

    func requirePremium(action: @escaping () -> Void) {
        if isPremium {
            action()
        } else {
            showPaywall = true
        }
    }
}

enum SubscriptionPlan: String, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case annual = "Annual"

    var price: String {
        switch self {
        case .weekly: return "$4.99/week"
        case .monthly: return "$14.99/month"
        case .annual: return "$99.99/year"
        }
    }

    var savings: String? {
        switch self {
        case .weekly: return nil
        case .monthly: return "Save 25%"
        case .annual: return "Save 60%"
        }
    }

    var description: String {
        switch self {
        case .weekly: return "Try it out"
        case .monthly: return "Most popular"
        case .annual: return "Best value"
        }
    }
}
