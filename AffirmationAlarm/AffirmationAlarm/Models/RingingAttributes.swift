import ActivityKit
import Foundation

struct RingingAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {}
    let alarmID: UUID
    let label: String
}
