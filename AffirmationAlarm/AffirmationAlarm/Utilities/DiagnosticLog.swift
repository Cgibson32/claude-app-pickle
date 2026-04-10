import Foundation

/// In-memory diagnostic log for troubleshooting AlarmKit sound playback.
/// Entries are visible in Settings → Alarm Diagnostics and can be copied
/// to the clipboard for sharing. Cleared on app restart — this is a
/// temporary debugging tool, not a persistent log.
@MainActor @Observable
final class DiagnosticLog {
    static let shared = DiagnosticLog()
    private(set) var entries: [String] = []

    func log(_ message: String) {
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let entry = "[\(ts)] \(message)"
        entries.append(entry)
        AppLogger.alarm.debug("\(entry, privacy: .public)")
    }

    func clear() { entries.removeAll() }

    /// Full log as a single string — for clipboard copy.
    var text: String { entries.joined(separator: "\n") }
}
