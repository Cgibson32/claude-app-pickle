import Foundation
import SwiftData

@Model
final class SequenceCompletion {
    var id: UUID
    var date: Date

    init(id: UUID = UUID(), date: Date = .now) {
        self.id = id
        self.date = date
    }
}
