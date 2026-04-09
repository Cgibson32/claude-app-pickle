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
/// - `audio` — MorningAudioRenderer, SpeechService, AVAudioSession
/// - `alarm` — AlarmKitScheduler, AlarmManager interactions
/// - `intent` — StopAndPlayClosingIntent, SnoozeMorningIntent
/// - `tts` — OpenAITTSService
/// - `claude` — ClaudeAPIService, AffirmationCacheService
/// - `subscription` — SubscriptionManager, StoreKit
enum AppLogger {
    private static let subsystem = "com.cgibson.affirmationalarm"

    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let alarm = Logger(subsystem: subsystem, category: "alarm")
    static let intent = Logger(subsystem: subsystem, category: "intent")
    static let tts = Logger(subsystem: subsystem, category: "tts")
    static let claude = Logger(subsystem: subsystem, category: "claude")
    static let subscription = Logger(subsystem: subsystem, category: "subscription")
}
