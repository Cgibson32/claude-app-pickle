import Foundation
import SwiftData

@Model
final class Affirmation {
    var id: UUID
    var text: String
    var generatedFor: Date
    var goalContext: String
    var wasSpoken: Bool

    init(
        id: UUID = UUID(),
        text: String,
        generatedFor: Date = .now,
        goalContext: String = "",
        wasSpoken: Bool = false
    ) {
        self.id = id
        self.text = text
        self.generatedFor = generatedFor
        self.goalContext = goalContext
        self.wasSpoken = wasSpoken
    }
}
