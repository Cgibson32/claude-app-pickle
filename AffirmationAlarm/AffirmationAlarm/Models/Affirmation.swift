import Foundation
import SwiftData

@Model
final class Affirmation {
    var id: UUID = UUID()
    var text: String = ""
    var generatedFor: Date = Date.now
    var goalContext: String = ""
    var isFavorited: Bool = false
    var favoriteType: Int = 0
    var isCustom: Bool = false
    var isPoolGenerated: Bool = false

    var isPriority: Bool { favoriteType == 1 }
    var isRotation: Bool { favoriteType == 2 }

    init(text: String = "", generatedFor: Date = .now, goalContext: String = "") {
        self.text = text
        self.generatedFor = generatedFor
        self.goalContext = goalContext
    }
}
