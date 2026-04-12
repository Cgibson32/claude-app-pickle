import AVFoundation
import Foundation

/// Single source of truth for "is morning+closing audio currently playing
/// for alarm X." Both the auto-play observer in `AlarmKitScheduler` and
/// `StopAndPlayClosingIntent` route through this actor. The second caller
/// gets a no-op if playback is already in progress or recently completed.
///
/// Uses actor isolation (not manual locks) for thread safety — the
/// observer runs on `@MainActor` and the `LiveActivityIntent.perform()`
/// runs off it, so both `await` naturally.
actor AlarmAudioPlayer {
    static let shared = AlarmAudioPlayer()

    private var playingAlarmIDs: Set<UUID> = []
    private var completedAlarmIDs: Set<UUID> = []

    enum PlaybackOutcome: Sendable {
        case played
        case alreadyPlaying
        case alreadyPlayed
        case noFiles
    }

    /// Play `morning-<id>.caf` then `closing-<id>.caf` for the given alarm.
    /// Returns immediately with `.alreadyPlaying` / `.alreadyPlayed` if
    /// another caller already triggered playback for this alarm.
    func playMorningAndClosing(for alarmID: UUID) async -> PlaybackOutcome {
        if playingAlarmIDs.contains(alarmID) { return .alreadyPlaying }
        if completedAlarmIDs.contains(alarmID) { return .alreadyPlayed }

        let soundsDir = MorningAudioRenderer.soundsDirectory()
        let morningURL = soundsDir.appendingPathComponent("morning-\(alarmID.uuidString).mp3")
        let closingURL = soundsDir.appendingPathComponent("closing-\(alarmID.uuidString).mp3")

        let hasMorning = FileManager.default.fileExists(atPath: morningURL.path)
        let hasClosing = FileManager.default.fileExists(atPath: closingURL.path)

        guard hasMorning || hasClosing else { return .noFiles }

        playingAlarmIDs.insert(alarmID)

        // Configure audio session for playback. Use `.playback` category
        // so audio plays even if the ring/silent switch is on.
        // NOTE: Do NOT call overrideOutputAudioPort(.speaker) — it throws
        // error -50 on iOS 26.1 and causes the entire audio session to
        // fail silently.
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
        } catch {
            AppLogger.alarm.error("AlarmAudioPlayer: audio session failed: \(error.localizedDescription, privacy: .public)")
            playingAlarmIDs.remove(alarmID)
            return .noFiles
        }

        if hasMorning {
            await playFile(at: morningURL)
        }

        if hasClosing {
            await playFile(at: closingURL)
        }

        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])

        playingAlarmIDs.remove(alarmID)
        completedAlarmIDs.insert(alarmID)

        // Forget after 60s so a rescheduled alarm with the same ID isn't
        // permanently blocked.
        Task {
            try? await Task.sleep(for: .seconds(60))
            completedAlarmIDs.remove(alarmID)
        }

        return .played
    }

    /// Whether playback is in progress for the given alarm.
    func isPlaying(alarmID: UUID) -> Bool {
        playingAlarmIDs.contains(alarmID)
    }

    // MARK: - Private

    /// Play a single audio file to completion. Uses `withExtendedLifetime`
    /// to prevent ARC from releasing the player during the `sleep` await.
    private func playFile(at url: URL) async {
        let player: AVAudioPlayer
        do {
            player = try AVAudioPlayer(contentsOf: url)
        } catch {
            AppLogger.alarm.error("AlarmAudioPlayer: init failed for \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return
        }

        player.volume = 1.0
        player.prepareToPlay()
        guard player.play() else {
            AppLogger.alarm.error("AlarmAudioPlayer: play() returned false for \(url.lastPathComponent, privacy: .public)")
            return
        }

        try? await Task.sleep(for: .seconds(player.duration + 0.3))
        withExtendedLifetime(player) {}
    }
}
