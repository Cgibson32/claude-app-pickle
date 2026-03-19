import Foundation
import SwiftData

@Model
final class EveningReflection {
    var id: UUID
    var mood: Int
    var goodThing: String
    var gratitude: String
    var date: Date

    init(id: UUID = UUID(), mood: Int = 2, goodThing: String = "", gratitude: String = "", date: Date = .now) {
        self.id = id
        self.mood = mood
        self.goodThing = goodThing
        self.gratitude = gratitude
        self.date = date
    }
}
