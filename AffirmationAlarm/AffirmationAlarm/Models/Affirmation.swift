import Foundation
import SwiftData

@Model
final class Affirmation {
    var id: UUID = UUID()
    var text: String = ""
    var generatedFor: Date = Date.now
    var goalContext: String = ""
    var wasSpoken: Bool = false
    var isFavorited: Bool = false

    init(text: String = "", generatedFor: Date = .now, goalContext: String = "") {
        self.text = text
        self.generatedFor = generatedFor
        self.goalContext = goalContext
    }
}
