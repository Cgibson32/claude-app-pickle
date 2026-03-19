import Foundation
import SwiftData

@Model
final class GratitudeEntry {
    var id: UUID
    var text: String
    var date: Date

    init(id: UUID = UUID(), text: String, date: Date = .now) {
        self.id = id
        self.text = text
        self.date = date
    }
}
