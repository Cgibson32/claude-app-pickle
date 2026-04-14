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

    // MARK: - State

    private var player: AVAudioPlayer?
    private let silenceURL: URL

    private var interruptionObserver: NSObjectProtocol?
    private var mediaServicesResetObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?

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
            AppLogger.alarm.info("BackgroundKeepAlive: started")
        } catch {
            AppLogger.alarm.error("BackgroundKeepAlive: start failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Stop silent audio and release the audio session. Also tears down
    /// the notification observers — they're re-installed by the next
    /// `start()`.
    func stop() {
        player?.stop()
        player = nil
        removeSessionObservers()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        AppLogger.alarm.info("BackgroundKeepAlive: stopped")
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
                Task { @MainActor in self?.handleInterruption(note) }
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
                Task { @MainActor in self?.logRouteChange(note) }
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

    /// `.began` logs only — the system has already paused our audio and
    /// we can't override it. `.ended` re-activates the session and
    /// resumes the silent loop so the observer Task stays alive for
    /// the next alarm fire.
    ///
    /// We resume regardless of `.shouldResume` because our audio is
    /// silent at volume 0: there's no user-audible consequence to
    /// resuming "too eagerly" and the keep-alive purpose requires it.
    private func handleInterruption(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else { return }

        switch type {
        case .began:
            AppLogger.alarm.info("BackgroundKeepAlive: interruption began")
        case .ended:
            let rawOptions = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            AppLogger.alarm.info(
                "BackgroundKeepAlive: interruption ended, shouldResume=\(options.contains(.shouldResume), privacy: .public)"
            )
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
        player?.stop()
        player = nil
        // `start()` will re-activate the session and re-install observers.
        start()
    }

    /// Diagnostic only. Route changes (headphones in/out, AirPods
    /// connect, etc.) can sometimes pause audio indirectly; logging lets
    /// us correlate with a failed wake-up in Console.app.
    private func logRouteChange(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let rawReason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason)
        else { return }
        AppLogger.alarm.info("BackgroundKeepAlive: route change reason=\(String(describing: reason), privacy: .public)")
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
        }
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
