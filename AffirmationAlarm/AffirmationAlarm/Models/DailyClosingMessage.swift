import Foundation
import SwiftData

@Model
final class DailyClosingMessage {
    var id: UUID
    var message: String
    var generatedFor: Date

    init(
        id: UUID = UUID(),
        message: String,
        generatedFor: Date = .now
    ) {
        self.id = id
        self.message = message
        self.generatedFor = generatedFor
    }
}
