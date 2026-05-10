import AVFoundation
import Foundation

/// Plays a 1-second silent CAF on infinite loop at volume 0 to keep the
/// app process alive via `UIBackgroundModes: [audio]`. Without an active
/// audio session, iOS suspends the process when backgrounded, killing
/// the `AlarmManager.alarmUpdates` observer that drives hands-free
/// affirmation playback.
///
/// This is a standard pattern used by alarm apps (Sleep Cycle, Alarmy)
/// to maintain background execution for alarm-related tasks. Battery
/// impact is negligible — silent audio at volume 0 doesn't drive the DAC.
///
/// ## Overnight robustness
///
/// Silent playback is *fragile* overnight: a phone call, Siri
/// invocation, or another app's exclusive-audio request will interrupt
/// our session. Without recovery, the app suspends and the next
/// morning's alarm fires into a dead observer — the user hears
/// `.default` and has to tap Stop manually to get affirmations.
///
/// We subscribe to three `AVAudioSession` notifications to self-heal:
///
/// - `interruptionNotification` — on `.ended`, re-activate and resume.
/// - `mediaServicesWereResetNotification` — rare but catastrophic;
///   the whole audio server restarted, so we rebuild from scratch.
/// - `routeChangeNotification` — purely diagnostic. Useful for
///   debugging "why did it stop" via Console.app on a wake-up that
///   failed mysteriously.
///
/// Start when any alarm is enabled, stop when all alarms are disabled.
@MainActor
final class BackgroundKeepAlive {

    // MARK: - Singleton

    static let shared = BackgroundKeepAlive()

    // MARK: - Diagnostics snapshot

    /// Immutable snapshot of keep-alive state for display in the
    /// on-device Diagnostics view.
    struct SessionSnapshot: Sendable {
        let isRunning: Bool
        let playerExists: Bool
        let playerIsPlaying: Bool
        let sessionCategory: String
        let sessionMode: String
        let sessionOptionsRaw: UInt
        let sessionIsOtherAudioPlaying: Bool
        let lastInterruption: TimestampedNote?
        let lastRouteChange: TimestampedNote?

        /// Placeholder shown in the view before the first `refresh()`
        /// call — matches the "never this session" display state.
        static let empty = SessionSnapshot(
            isRunning: false,
            playerExists: false,
            playerIsPlaying: false,
            sessionCategory: "(unknown)",
            sessionMode: "(unknown)",
            sessionOptionsRaw: 0,
            sessionIsOtherAudioPlaying: false,
            lastInterruption: nil,
            lastRouteChange: nil
        )
    }

    /// Small Sendable pair used by both `lastInterruption` and
    /// `lastRouteChange`. Introduced instead of labeled tuples so the
    /// Sendable conformance of `SessionSnapshot` is unambiguous under
    /// Swift 6 strict concurrency.
    struct TimestampedNote: Sendable {
        let date: Date
        let detail: String
    }

    /// Observable for Diagnostics view. Uses a simple closure-based
    /// accessor rather than `@Observable` so the file keeps its
    /// singleton+state design without pulling in SwiftUI imports.
    func sessionSnapshot() -> SessionSnapshot {
        let session = AVAudioSession.sharedInstance()
        return SessionSnapshot(
            isRunning: isRunning,
            playerExists: player != nil,
            playerIsPlaying: player?.isPlaying ?? false,
            sessionCategory: session.category.rawValue,
            sessionMode: session.mode.rawValue,
            sessionOptionsRaw: session.categoryOptions.rawValue,
            sessionIsOtherAudioPlaying: session.isOtherAudioPlaying,
            lastInterruption: lastInterruption,
            lastRouteChange: lastRouteChange
        )
    }

    // MARK: - State

    private var player: AVAudioPlayer?
    private let silenceURL: URL

    private var interruptionObserver: NSObjectProtocol?
    private var mediaServicesResetObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?

    private var recoveryTask: Task<Void, Never>?
    private var healthCheckTask: Task<Void, Never>?

    private var lastInterruption: TimestampedNote?
    private var lastRouteChange: TimestampedNote?

    private init() {
        silenceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("silence-keepalive.caf")
    }

    // MARK: - Public API

    var isRunning: Bool { player?.isPlaying ?? false }

    /// Start silent background audio. Safe to call multiple times — if
    /// silent playback is already running we install any missing session
    /// observers (they can be cleared by `stop()` while the player lived)
    /// and return.
    func start() {
        installSessionObservers()

        guard !isRunning else { return }

        do {
            try generateSilenceFileIfNeeded()
            try activateSession()
            try startSilentPlayback()
            startHealthCheck()
            AppLogger.alarm.info("BackgroundKeepAlive: started")
            DiagnosticsLog.shared.log("keep-alive", "started")
        } catch {
            AppLogger.alarm.error("BackgroundKeepAlive: start failed: \(error.localizedDescription, privacy: .public)")
            DiagnosticsLog.shared.log("keep-alive", "start failed: \(error.localizedDescription)")
        }
    }

    /// Stop silent audio and release the audio session. Also tears down
    /// the notification observers — they're re-installed by the next
    /// `start()`.
    func stop() {
        player?.stop()
        player = nil
        recoveryTask?.cancel()
        recoveryTask = nil
        stopHealthCheck()
        removeSessionObservers()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        AppLogger.alarm.info("BackgroundKeepAlive: stopped")
        DiagnosticsLog.shared.log("keep-alive", "stopped")
    }

    // MARK: - Session + playback primitives

    private func activateSession() throws {
        let session = AVAudioSession.sharedInstance()
        // `.mixWithOthers` so music/podcasts the user had going before
        // bed keep playing. `.playback` so audio stays alive with the
        // screen off (requires `UIBackgroundModes: [audio]` in Info.plist).
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true, options: [])
    }

    private func startSilentPlayback() throws {
        let p = try AVAudioPlayer(contentsOf: silenceURL)
        p.numberOfLoops = -1  // infinite
        p.volume = 0.0
        p.prepareToPlay()
        p.play()
        player = p
    }

    // MARK: - Self-healing observers

    private func installSessionObservers() {
        let center = NotificationCenter.default
        let session = AVAudioSession.sharedInstance()

        if interruptionObserver == nil {
            interruptionObserver = center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: session,
                queue: .main
            ) { [weak self] note in
                // Extract Sendable primitives while we're still on the
                // posting queue; `Notification` itself isn't Sendable and
                // can't cross into the MainActor Task under Swift 6.
                let rawType = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
                let rawOptions = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
                Task { @MainActor in
                    self?.handleInterruption(rawType: rawType, rawOptions: rawOptions)
                }
            }
        }

        if mediaServicesResetObserver == nil {
            mediaServicesResetObserver = center.addObserver(
                forName: AVAudioSession.mediaServicesWereResetNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.rebuildAfterMediaServicesReset() }
            }
        }

        if routeChangeObserver == nil {
            routeChangeObserver = center.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] note in
                let rawReason = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
                Task { @MainActor in self?.logRouteChange(rawReason: rawReason) }
            }
        }
    }

    private func removeSessionObservers() {
        let center = NotificationCenter.default
        if let o = interruptionObserver { center.removeObserver(o) }
        if let o = mediaServicesResetObserver { center.removeObserver(o) }
        if let o = routeChangeObserver { center.removeObserver(o) }
        interruptionObserver = nil
        mediaServicesResetObserver = nil
        routeChangeObserver = nil
    }

    // MARK: - Interruption handling

    /// On `.began`: immediately attempt to resume silent audio. The
    /// alarm daemon's non-mixable session interrupted us, and if we
    /// wait for `.ended` iOS may suspend our process first (the grace
    /// period after audio stops is only ~3 seconds). By attempting
    /// `resumeSilence()` right away — and retrying in a tight loop —
    /// we keep the run-loop alive and re-grab the audio session the
    /// moment the system releases it.
    ///
    /// On `.ended`: standard resume, same as before.
    private func handleInterruption(rawType: UInt?, rawOptions: UInt?) {
        guard let rawType, let type = AVAudioSession.InterruptionType(rawValue: rawType) else {
            return
        }

        switch type {
        case .began:
            AppLogger.alarm.info("BackgroundKeepAlive: interruption began")
            lastInterruption = TimestampedNote(date: Date(), detail: "began")
            DiagnosticsLog.shared.log("keep-alive", "interruption began — starting recovery loop")
            resumeSilence()
            startRecoveryLoop()
        case .ended:
            let rawOpts = rawOptions ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOpts)
            AppLogger.alarm.info(
                "BackgroundKeepAlive: interruption ended, shouldResume=\(options.contains(.shouldResume), privacy: .public)"
            )
            lastInterruption = TimestampedNote(
                date: Date(),
                detail: "ended (shouldResume=\(options.contains(.shouldResume)))"
            )
            DiagnosticsLog.shared.log("keep-alive", "interruption ended shouldResume=\(options.contains(.shouldResume))")
            resumeSilence()
        @unknown default:
            break
        }
    }

    /// `mediaServicesWereReset` means the audio server crashed and every
    /// session/player in the process is invalid. Everything must be
    /// rebuilt from scratch.
    private func rebuildAfterMediaServicesReset() {
        AppLogger.alarm.error("BackgroundKeepAlive: media services reset, rebuilding")
        DiagnosticsLog.shared.log("keep-alive", "media services reset — rebuilding")
        player?.stop()
        player = nil
        // `start()` will re-activate the session and re-install observers.
        start()
    }

    /// Diagnostic only. Route changes (headphones in/out, AirPods
    /// connect, etc.) can sometimes pause audio indirectly; logging lets
    /// us correlate with a failed wake-up in Console.app.
    private func logRouteChange(rawReason: UInt?) {
        guard let rawReason, let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason) else {
            return
        }
        let reasonLabel = String(describing: reason)
        AppLogger.alarm.info("BackgroundKeepAlive: route change reason=\(reasonLabel, privacy: .public)")
        lastRouteChange = TimestampedNote(date: Date(), detail: reasonLabel)
        DiagnosticsLog.shared.log("keep-alive", "route change reason=\(reasonLabel)")
    }

    /// Re-activate the session and resume silent playback. Called both
    /// from interruption-ended and externally if a caller knows the
    /// session was deactivated (e.g., after the observer finishes
    /// playing affirmation audio).
    private func resumeSilence() {
        do {
            try activateSession()
            if let existing = player {
                if !existing.isPlaying { existing.play() }
            } else {
                try startSilentPlayback()
            }
        } catch {
            AppLogger.alarm.error("BackgroundKeepAlive: resume failed: \(error.localizedDescription, privacy: .public)")
            DiagnosticsLog.shared.log("keep-alive", "resume failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Recovery loop

    /// Tight retry loop that fires every 500ms for up to 30 seconds
    /// after an interruption begins. Each iteration tries to re-activate
    /// the audio session and resume silence. The loop keeps the run-loop
    /// alive (preventing suspension) and catches the moment the system
    /// releases the audio session.
    private func startRecoveryLoop() {
        recoveryTask?.cancel()
        recoveryTask = Task { @MainActor [weak self] in
            for attempt in 1...60 {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .milliseconds(500))
                guard let self else { return }
                if self.player?.isPlaying == true {
                    DiagnosticsLog.shared.log("keep-alive", "recovery succeeded on attempt \(attempt)")
                    return
                }
                self.resumeSilence()
            }
            DiagnosticsLog.shared.log("keep-alive", "recovery loop exhausted after 30s")
        }
    }

    // MARK: - Periodic health check

    /// Runs every 30 seconds while keep-alive is active. If the silent
    /// player has stopped (interrupted without notification, audio route
    /// change, etc.) this restarts it before iOS notices and suspends.
    func startHealthCheck() {
        healthCheckTask?.cancel()
        healthCheckTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard let self, !Task.isCancelled else { return }
                if self.player?.isPlaying != true {
                    DiagnosticsLog.shared.log("keep-alive", "health check: player stopped — restarting")
                    self.resumeSilence()
                }
            }
        }
    }

    private func stopHealthCheck() {
        healthCheckTask?.cancel()
        healthCheckTask = nil
    }

    // MARK: - Silence generation

    /// Create a 1-second silent CAF at `silenceURL` using AVAudioFile.
    /// Writes a zeroed PCM buffer into a CAF container.
    private func generateSilenceFileIfNeeded() throws {
        guard !FileManager.default.fileExists(atPath: silenceURL.path) else { return }

        let sampleRate: Double = 44100
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        ) else {
            throw NSError(domain: "BackgroundKeepAlive", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not create audio format"])
        }

        let frameCount = AVAudioFrameCount(sampleRate) // 1 second
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(domain: "BackgroundKeepAlive", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Could not create PCM buffer"])
        }
        buffer.frameLength = frameCount // buffer is zero-filled = silence

        let file = try AVAudioFile(forWriting: silenceURL, settings: format.settings)
        try file.write(from: buffer)
    }
}
