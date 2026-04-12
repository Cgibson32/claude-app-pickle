import Foundation
import SwiftData

@Model
final class Affirmation {
    var id: UUID = UUID()
    var text: String = ""
    var generatedFor: Date = Date.now
    var goalContext: String = ""
    // TODO(v1.1): Remove alongside a proper VersionedSchema migration.
    // Vestigial — never read. Kept to avoid SwiftData schema change.
    var wasSpoken: Bool = false
    var isFavorited: Bool = false
    var favoriteType: Int = 0
    var isCustom: Bool = false

    var isPriority: Bool { favoriteType == 1 }
    var isRotation: Bool { favoriteType == 2 }

    init(text: String = "", generatedFor: Date = .now, goalContext: String = "") {
        self.text = text
        self.generatedFor = generatedFor
        self.goalContext = goalContext
    }
}
