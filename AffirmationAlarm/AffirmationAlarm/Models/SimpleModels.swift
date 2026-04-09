import Foundation
import SwiftData

@Model
final class DailyClosingMessage {
    var id: UUID = UUID()
    var message: String = ""
    var generatedFor: Date = Date.now

    init(message: String = "", generatedFor: Date = .now) {
        self.message = message
        self.generatedFor = generatedFor
    }
}

@Model
final class GratitudeEntry {
    var id: UUID = UUID()
    var text: String = ""
    var date: Date = Date.now

    init(text: String = "", date: Date = .now) {
        self.text = text
        self.date = date
    }
}

@Model
final class DailyIntention {
    var id: UUID = UUID()
    var text: String = ""
    var date: Date = Date.now

    init(text: String = "", date: Date = .now) {
        self.text = text
        self.date = date
    }
}

@Model
final class EveningReflection {
    var id: UUID = UUID()
    var mood: Int = 2
    var goodThing: String = ""
    var gratitude: String = ""
    var date: Date = Date.now

    init(mood: Int = 2, goodThing: String = "", gratitude: String = "", date: Date = .now) {
        self.mood = mood
        self.goodThing = goodThing
        self.gratitude = gratitude
        self.date = date
    }
}
