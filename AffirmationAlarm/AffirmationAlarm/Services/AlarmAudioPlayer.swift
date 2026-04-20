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

/// Tunable constants for the pre-affirmation bird-chirp intro. Kept in
/// one place so swapping the file or retuning the duration/volume is a
/// one-line change.
private enum AlarmIntro {
    /// Bundle resource name (without extension) of the intro audio.
    /// Must exist as `<stem>.caf` in the app bundle.
    static let soundStem = "alarm_birds"

    /// Total intro length in milliseconds — hold + fade combined.
    static let totalMs: Int = 2000

    /// Trailing fade-out so the cut into "Good morning, <name>" doesn't
    /// feel abrupt. Must be less than `totalMs`.
    static let fadeMs: Int = 300

    /// Softer than the spoken affirmations (which play at volume 1.0)
    /// so the birds feel like a gentle lead-in, not a second alarm.
    static let volume: Float = 0.6
}

actor AlarmAudioPlayer {

    // MARK: - Singleton

    static let shared = AlarmAudioPlayer()

    private init() {}

    // MARK: - Tunables

    /// dB boost applied to the spoken affirmations and closing — NOT the
    /// birds intro. `AVAudioUnitEQ.globalGain` accepts -96…+24; +3 is a
    /// modest bump that adds perceptible loudness headroom above the
    /// device's media volume ceiling without risking clipping on the
    /// TTS's louder syllables.
    static let affirmationGainDB: Float = 3.0

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

    /// Last playback outcome + timestamp + alarm ID, for the on-device
    /// Diagnostics view. Published via `lastPlaybackSummary()`.
    private var lastOutcome: (outcome: PlaybackOutcome, date: Date, alarmID: UUID)?

    // MARK: - Diagnostics

    struct PlaybackSummary: Sendable {
        let outcome: String
        let date: Date
        let alarmID: UUID
    }

    /// Snapshot of the most recent `playMorningAndClosing` call — used
    /// by the Diagnostics view to show what happened last time.
    func lastPlaybackSummary() -> PlaybackSummary? {
        guard let last = lastOutcome else { return nil }
        return PlaybackSummary(
            outcome: last.outcome.description,
            date: last.date,
            alarmID: last.alarmID
        )
    }

    // MARK: - Public API

    /// Play `morning-<id>.mp3` followed by `closing-<id>.mp3`. Either
    /// file may be missing; we play whichever exists. Returns immediately
    /// with `.alreadyPlaying` / `.alreadyPlayed` if another call already
    /// fired for this alarm.
    ///
    /// Purgatory (`recentlyCompleted`) is only set after audio actually
    /// got out — not on setup failures. The intent's sandboxed audio
    /// session intermittently fails on iOS 26.3.1, and when it does we
    /// want the foreground retry from `checkPendingMorningPlayback` to
    /// succeed rather than get short-circuited by purgatory.
    func playMorningAndClosing(for alarmID: UUID) async -> PlaybackOutcome {
        DiagnosticsLog.shared.log("player", "start \(alarmID.uuidString.prefix(8))")

        if playing.contains(alarmID) {
            return record(outcome: .alreadyPlaying, alarmID: alarmID)
        }
        if recentlyCompleted.contains(alarmID) {
            return record(outcome: .alreadyPlayed, alarmID: alarmID)
        }

        let (morning, closing) = filesFor(alarmID: alarmID)
        guard morning != nil || closing != nil else {
            return record(outcome: .noFiles, alarmID: alarmID)
        }

        playing.insert(alarmID)
        // Release the `playing` slot no matter how we exit. Purgatory is
        // set explicitly on success paths below.
        defer { playing.remove(alarmID) }

        guard await activateAudioSession() else {
            return record(outcome: .audioSessionUnavailable, alarmID: alarmID)
        }

        await playIntro()
        if let morning { await playFile(at: morning) }
        if let closing { await playFile(at: closing) }

        // Do NOT deactivate the session here. We're sharing keep-alive's
        // `.playback + .mixWithOthers` session; tearing it down would
        // kill keep-alive's silent loop and force `BackgroundKeepAlive`
        // to restart (which it does via `handleFire`, but that's a
        // window where iOS could suspend the process).
        markCompleted(alarmID: alarmID)
        return record(outcome: .played, alarmID: alarmID)
    }

    /// Record the outcome on the shared diagnostics log and the actor's
    /// `lastOutcome` slot in one place. Returns the outcome for the
    /// caller so call sites can be a single-line `return record(...)`.
    private func record(outcome: PlaybackOutcome, alarmID: UUID) -> PlaybackOutcome {
        lastOutcome = (outcome, Date(), alarmID)
        DiagnosticsLog.shared.log("player", "\(alarmID.uuidString.prefix(8)) outcome=\(outcome)")
        return outcome
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
    ///
    /// ## iOS 26.3.1 session activation retry
    ///
    /// From device logs: when the observer fires during an active
    /// AlarmKit alarm, iOS sends an audio session interruption
    /// notification for ~1.3 seconds around the alarm's audio release.
    /// `setActive(true)` called during that window throws
    /// `"Session activation failed"`. Crucially the interruption ends
    /// naturally after the handoff — we just have to retry past it.
    ///
    /// We retry up to 3 times with 300ms backoff. Total worst case is
    /// ~1 second of extra delay on top of the 400ms we already wait
    /// after `manager.cancel(id:)`, which is enough headroom to cover
    /// the observed interruption window.
    ///
    /// We match the keep-alive's category (`.playback + .mixWithOthers`)
    /// so the activation is a near-noop when it works on the first
    /// try — no transition, no ownership contention.
    private func activateAudioSession() async -> Bool {
        let session = AVAudioSession.sharedInstance()
        let attempts = 4
        let backoff: Duration = .milliseconds(300)

        for attempt in 1...attempts {
            do {
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try session.setActive(true, options: [])
                if attempt > 1 {
                    DiagnosticsLog.shared.log("player", "session activated on attempt \(attempt)")
                }
                return true
            } catch {
                let msg = error.localizedDescription
                if attempt < attempts {
                    DiagnosticsLog.shared.log("player", "session attempt \(attempt) failed: \(msg); retry in 300ms")
                    try? await Task.sleep(for: backoff)
                } else {
                    AppLogger.alarm.error("AlarmAudioPlayer: session failed after \(attempts) attempts: \(msg, privacy: .public)")
                    DiagnosticsLog.shared.log("player", "session failed after \(attempts) attempts: \(msg)")
                    return false
                }
            }
        }
        return false
    }

    /// Calming 2-second bird-chirp intro before the affirmations. Uses
    /// the bundled `alarm_birds.caf` (same asset backing the "Birds"
    /// alarm sound option, so we don't ship a duplicate), played softer
    /// than the spoken content and fading out over the last 300ms so
    /// the cut into "Good morning, <name>" doesn't feel abrupt.
    ///
    /// Silently skipped if the file is missing or won't open — the
    /// intro is a nicety, not a requirement, and a failure here must
    /// not block the affirmation playback.
    private func playIntro() async {
        let stem = AlarmIntro.soundStem
        guard let url = Bundle.main.url(forResource: stem, withExtension: "caf"),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            DiagnosticsLog.shared.log("player", "intro skipped — \(stem).caf missing")
            return
        }
        player.volume = AlarmIntro.volume
        player.prepareToPlay()
        guard player.play() else {
            DiagnosticsLog.shared.log("player", "intro play() returned false")
            return
        }
        DiagnosticsLog.shared.log("player", "intro playing \(url.lastPathComponent) for \(AlarmIntro.totalMs)ms")

        let fadeMs = AlarmIntro.fadeMs
        let holdMs = AlarmIntro.totalMs - fadeMs
        try? await Task.sleep(for: .milliseconds(holdMs))
        player.setVolume(0.0, fadeDuration: Double(fadeMs) / 1000.0)
        try? await Task.sleep(for: .milliseconds(fadeMs))
        player.stop()
        withExtendedLifetime(player) {}
        DiagnosticsLog.shared.log("player", "intro done")
    }

    /// Play a single affirmation file boosted by `affirmationGainDB`.
    ///
    /// `AVAudioPlayer.volume` is a 0…1 multiplier and cannot exceed the
    /// device's current media volume — setting it to 1.0 is already the
    /// ceiling for that API. To add real headroom above the system
    /// volume we route playback through `AVAudioEngine` with an
    /// `AVAudioUnitEQ.globalGain` stage, which accepts dB values from
    /// -96 to +24. +3 dB doubles perceived loudness modestly without
    /// pushing so hard that a quiet passage of the TTS (inhales,
    /// sibilants) clips the speaker.
    ///
    /// On AVAudioEngine failure we fall back to the plain
    /// `AVAudioPlayer` path so a broken engine configuration can never
    /// silently drop the morning affirmations.
    private func playFile(at url: URL) async {
        let file: AVAudioFile
        do {
            file = try AVAudioFile(forReading: url)
        } catch {
            AppLogger.alarm.error("AlarmAudioPlayer: AVAudioFile init failed for \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
            DiagnosticsLog.shared.log("player", "file init failed \(url.lastPathComponent): \(error.localizedDescription)")
            await playFileFallback(at: url)
            return
        }

        let engine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()
        let eq = AVAudioUnitEQ(numberOfBands: 1)
        eq.globalGain = Self.affirmationGainDB

        engine.attach(playerNode)
        engine.attach(eq)

        let format = file.processingFormat
        engine.connect(playerNode, to: eq, format: format)
        engine.connect(eq, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
        } catch {
            AppLogger.alarm.error("AlarmAudioPlayer: engine start failed: \(error.localizedDescription, privacy: .public)")
            DiagnosticsLog.shared.log("player", "engine start failed \(url.lastPathComponent): \(error.localizedDescription); using fallback")
            await playFileFallback(at: url)
            return
        }

        playerNode.scheduleFile(file, at: nil, completionHandler: nil)
        playerNode.play()

        let duration = Double(file.length) / file.processingFormat.sampleRate
        DiagnosticsLog.shared.log(
            "player",
            "playing \(url.lastPathComponent) duration=\(String(format: "%.2f", duration))s gain=+\(Self.affirmationGainDB)dB"
        )

        try? await Task.sleep(for: .seconds(duration + 0.3))

        let finished = !playerNode.isPlaying
        playerNode.stop()
        engine.stop()
        withExtendedLifetime((engine, playerNode, eq, file)) {}

        DiagnosticsLog.shared.log(
            "player",
            "done \(url.lastPathComponent) finished=\(finished)"
        )
    }

    /// Plain-`AVAudioPlayer` fallback path used only when the boosted
    /// AVAudioEngine route fails to initialize. No dB gain — the user
    /// still hears the affirmation, just at the system-ceiling volume.
    private func playFileFallback(at url: URL) async {
        let player: AVAudioPlayer
        do {
            player = try AVAudioPlayer(contentsOf: url)
        } catch {
            AppLogger.alarm.error("AlarmAudioPlayer: fallback init failed for \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
            DiagnosticsLog.shared.log("player", "fallback init failed \(url.lastPathComponent): \(error.localizedDescription)")
            return
        }

        player.volume = 1.0
        player.prepareToPlay()

        DiagnosticsLog.shared.log("player", "fallback playing \(url.lastPathComponent) duration=\(String(format: "%.2f", player.duration))s")

        guard player.play() else {
            AppLogger.alarm.error("AlarmAudioPlayer: fallback play() returned false for \(url.lastPathComponent, privacy: .public)")
            DiagnosticsLog.shared.log("player", "fallback play() returned false for \(url.lastPathComponent)")
            return
        }

        try? await Task.sleep(for: .seconds(player.duration + 0.3))
        let finished = !player.isPlaying
        let played = player.currentTime
        DiagnosticsLog.shared.log(
            "player",
            "fallback done \(url.lastPathComponent) played=\(String(format: "%.2f", played))s finished=\(finished)"
        )
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
