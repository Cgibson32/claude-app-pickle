import Foundation
import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var dailyFocus: DailyFocus
    @Published var greeting: String
    @Published var quote: String
    @Published var showBeforePlaySheet: Bool = false
    @Published var showAfterPlaySheet: Bool = false

    init() {
        self.dailyFocus = DailyFocus.example
        self.greeting = HomeViewModel.generateGreeting()
        self.quote = MockDataService.quotes.randomElement() ?? "Play with purpose today."
    }

    static func generateGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Welcome back"
        }
    }

    func refreshQuote() {
        withAnimation {
            quote = MockDataService.quotes.randomElement() ?? "Play with purpose today."
        }
    }
}
