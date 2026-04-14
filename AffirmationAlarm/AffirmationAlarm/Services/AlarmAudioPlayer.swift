import AVFoundation
import Foundation

/// Single source of truth for alarm audio playback across every entry
/// point in the app:
///
/// 1. **`AlarmKitScheduler.handleFire`** — observer sees `.alerting`
///    while app is foregrounded (Sleep Mode).
/// 2. **`StopAndPlayClosingIntent.perform`** — user slides Stop on the
///    AlarmKit alert.
/// 3. **`AffirmationAlarmApp.checkPendingMorningPlayback`** — on iOS
///    26.1+, sliding Stop reopens the app even with
///    `openAppWhenRun = false`, so the foreground re-check is a third
///    entry point when the intent's background audio session failed.
///
/// All three call `playMorningAndClosing(for:)`. The actor's state
/// machine guarantees that only one playback runs per alarm ID, and a
/// just-completed playback is remembered for 60 seconds so a reopened
/// app doesn't double-play.
///
/// The class is an `actor` so callers don't need explicit locks — every
/// state mutation happens inside the actor's serial execution.
actor AlarmAudioPlayer {

    // MARK: - Singleton

    static let shared = AlarmAudioPlayer()

    private init() {}

    // MARK: - Types

    enum PlaybackOutcome: Sendable, CustomStringConvertible {
        /// At least one file played successfully.
        case played
        /// Another call for this alarm is currently in progress.
        case alreadyPlaying
        /// This alarm was played in the last 60 seconds.
        case alreadyPlayed
        /// Neither `morning-*.mp3` nor `closing-*.mp3` exists on disk.
        case noFiles
        /// Audio session configuration failed; nothing was played.
        case audioSessionUnavailable

        var description: String {
            switch self {
            case .played: return "played"
            case .alreadyPlaying: return "alreadyPlaying"
            case .alreadyPlayed: return "alreadyPlayed"
            case .noFiles: return "noFiles"
            case .audioSessionUnavailable: return "audioSessionUnavailable"
            }
        }
    }

    // MARK: - State

    /// Alarms whose playback is currently in progress.
    private var playing: Set<UUID> = []

    /// Alarms that completed within the last 60s. Prevents double-play
    /// when the observer and the reopened-app scenePhase both fire.
    private var recentlyCompleted: Set<UUID> = []

    /// Lifecycle tasks for purgatory cleanup, keyed by alarm ID.
    /// Stored so we can cancel them if a new playback starts for the
    /// same ID within the purgatory window.
    private var purgatoryTasks: [UUID: Task<Void, Never>] = [:]

    /// Purgatory window: how long we remember a just-completed playback.
    /// Tuned so the reopened-app scenePhase check (which runs shortly
    /// after the intent's `AlarmAudioPlayer` call) gets `.alreadyPlayed`
    /// rather than re-triggering a second playback.
    private let purgatoryWindow: Duration = .seconds(60)

    // MARK: - Public API

    /// Play `morning-<id>.mp3` followed by `closing-<id>.mp3`. Either
    /// file may be missing; we play whichever exists. Returns immediately
    /// with `.alreadyPlaying` / `.alreadyPlayed` if another call already
    /// fired for this alarm.
    func playMorningAndClosing(for alarmID: UUID) async -> PlaybackOutcome {
        if playing.contains(alarmID) { return .alreadyPlaying }
        if recentlyCompleted.contains(alarmID) { return .alreadyPlayed }

        let (morning, closing) = filesFor(alarmID: alarmID)
        guard morning != nil || closing != nil else { return .noFiles }

        playing.insert(alarmID)
        defer {
            playing.remove(alarmID)
            markCompleted(alarmID: alarmID)
        }

        guard activateAudioSession() else {
            return .audioSessionUnavailable
        }

        if let morning { await playFile(at: morning) }
        if let closing { await playFile(at: closing) }

        deactivateAudioSession()
        return .played
    }

    /// Whether playback is currently in progress for the given alarm.
    /// Useful for UI that wants to reflect "Playing..." state.
    func isPlaying(alarmID: UUID) -> Bool {
        playing.contains(alarmID)
    }

    // MARK: - Private

    private func filesFor(alarmID: UUID) -> (morning: URL?, closing: URL?) {
        let dir = MorningAudioRenderer.soundsDirectory()
        let morning = dir.appendingPathComponent("morning-\(alarmID.uuidString).mp3")
        let closing = dir.appendingPathComponent("closing-\(alarmID.uuidString).mp3")
        let fm = FileManager.default
        return (
            fm.fileExists(atPath: morning.path) ? morning : nil,
            fm.fileExists(atPath: closing.path) ? closing : nil
        )
    }

    /// Configure the shared audio session for loud playback. `.playback`
    /// category routes through the speaker and ignores the ring/silent
    /// switch — exactly what we want for an alarm.
    ///
    /// NOTE: do NOT call `overrideOutputAudioPort(.speaker)` — it throws
    /// OSStatus -50 on iOS 26.1+ and takes the whole session down with it.
    /// `.playback` already routes through the speaker by default.
    private func activateAudioSession() -> Bool {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
            return true
        } catch {
            AppLogger.alarm.error("AlarmAudioPlayer: audio session failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    /// Play a single audio file and await its completion. Uses
    /// `withExtendedLifetime` to keep the `AVAudioPlayer` alive across
    /// the `sleep` — without it ARC can release the player mid-playback
    /// while we're suspended on the sleep.
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

    /// Record completion in purgatory and schedule its expiry. If there's
    /// already a purgatory task for this alarm (shouldn't happen, but
    /// harmless if it does), cancel it before spawning the new one.
    private func markCompleted(alarmID: UUID) {
        recentlyCompleted.insert(alarmID)
        purgatoryTasks[alarmID]?.cancel()

        let window = purgatoryWindow
        purgatoryTasks[alarmID] = Task { [weak self] in
            try? await Task.sleep(for: window)
            guard !Task.isCancelled else { return }
            await self?.expirePurgatory(alarmID: alarmID)
        }
    }

    private func expirePurgatory(alarmID: UUID) {
        recentlyCompleted.remove(alarmID)
        purgatoryTasks[alarmID] = nil
    }
}
