import ActivityKit
import Foundation

struct RingingAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var isRinging: Bool = false
    }
    let alarmID: UUID
    let label: String
}
