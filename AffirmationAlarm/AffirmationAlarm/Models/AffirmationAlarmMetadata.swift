import AlarmKit
import Foundation

/// Per-alarm metadata attached to every AlarmKit entry. Lives in its
/// own file so the Widget Extension target can share the type without
/// pulling in the whole scheduler. Conformances (Codable/Hashable/
/// Sendable) auto-synthesize because every stored property is itself
/// Codable/Hashable/Sendable.
struct AffirmationAlarmMetadata: AlarmMetadata {
    let alarmID: UUID
    let label: String
}
