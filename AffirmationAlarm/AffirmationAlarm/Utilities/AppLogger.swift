import Foundation
import os

/// Central `os.Logger` subsystem for Affirmation Alarm. One subsystem,
/// multiple categories so Console.app and Xcode's log viewer can filter
/// by area. Use these instead of `print()` so production errors are
/// visible on real devices (Console.app → search by subsystem).
///
/// Usage:
/// ```
/// AppLogger.audio.error("render failed: \(error, privacy: .public)")
/// AppLogger.alarm.info("scheduled \(id)")
/// ```
///
/// The categories roughly map to the services they live in:
/// - `audio` — MorningAudioRenderer, AlarmAudioPlayer, AVAudioSession
/// - `alarm` — AlarmKitScheduler, AlarmManager interactions
/// - `intent` — StopAndPlayClosingIntent, SnoozeMorningIntent
/// - `tts — ElevenLabsTTSService
/// - `claude` — ClaudeAPIService, AffirmationCacheService
enum AppLogger {
    private static let subsystem = "com.cgibson.affirmationalarm"

    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let alarm = Logger(subsystem: subsystem, category: "alarm")
    static let intent = Logger(subsystem: subsystem, category: "intent")
    static let tts = Logger(subsystem: subsystem, category: "tts")
    static let claude = Logger(subsystem: subsystem, category: "claude")
}

// MARK: - In-memory diagnostics log

/// Thread-safe ring buffer that mirrors explicitly-tagged events for
/// display in the on-device Diagnostics view. We can't intercept
/// `os.Logger` without rewriting every call site (Swift 6 `OSLogMessage`
/// interpolation isn't a plain String), so instead we append here at key
/// transitions — observer fires, keep-alive interruptions, intent
/// invocations, render results.
///
/// Purpose: let the user see on-device why the alarm pipeline behaves a
/// given way, without having to open Console.app on a Mac. The
/// Diagnostics view polls `snapshot()` on appear and refresh.
final class DiagnosticsLog: @unchecked Sendable {

    static let shared = DiagnosticsLog()

    struct Entry: Identifiable, Hashable, Sendable {
        let id = UUID()
        let timestamp: Date
        let tag: String
        let message: String
    }

    private let lock = NSLock()
    private var entries: [Entry] = []
    private let maxEntries = 200

    private init() {}

    /// Append a tagged event. `tag` is a short category like
    /// "keep-alive" / "observer" / "intent" / "render" — used for
    /// visual grouping in the view.
    func log(_ tag: String, _ message: String) {
        lock.lock()
        defer { lock.unlock() }
        entries.append(Entry(timestamp: Date(), tag: tag, message: message))
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    func snapshot() -> [Entry] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll()
    }

    /// Plain-text dump for the "Copy to clipboard" button in the view.
    func asText() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss.SSS"
        return snapshot().map { entry in
            "\(fmt.string(from: entry.timestamp)) [\(entry.tag)] \(entry.message)"
        }.joined(separator: "\n")
    }
}
