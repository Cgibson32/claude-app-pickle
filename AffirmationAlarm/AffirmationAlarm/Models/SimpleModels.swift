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

/// A single sentence the user writes at night. The next morning's first
/// affirmation references it directly so the ritual feels seen, not
/// generic. Read by `AffirmationCacheService` if `createdAt` is within
/// the freshness window; older rows are ignored (not deleted — kept as a
/// quiet record the user can scroll later if we add a journal view).
@Model
final class EveningIntention {
    var id: UUID = UUID()
    var text: String = ""
    var createdAt: Date = Date.now

    init(text: String = "", createdAt: Date = .now) {
        self.text = text
        self.createdAt = createdAt
    }
}
