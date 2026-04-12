import AVFoundation
import Foundation

/// Plays a 1-second silent CAF on infinite loop at volume 0 to keep the
/// app process alive via `UIBackgroundModes: [audio]`. Without an active
/// audio session, iOS suspends the process when backgrounded, killing the
/// `AlarmManager.alarmUpdates` observer that drives auto-play.
///
/// This is a standard pattern used by alarm apps (Sleep Cycle, Alarmy)
/// to maintain background execution for alarm-related tasks. Battery
/// impact is negligible — silent audio at volume 0 doesn't drive the DAC.
///
/// Start when any alarm is enabled, stop when all alarms are disabled.
@MainActor
final class BackgroundKeepAlive {
    static let shared = BackgroundKeepAlive()

    private var player: AVAudioPlayer?
    private let silenceURL: URL

    private init() {
        silenceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("silence-keepalive.caf")
    }

    var isRunning: Bool { player?.isPlaying ?? false }

    /// Start silent background audio. Safe to call multiple times —
    /// no-ops if already running.
    func start() {
        guard !isRunning else { return }

        do {
            try generateSilenceFileIfNeeded()

            // .mixWithOthers so we don't interrupt music/podcasts.
            // .playback so audio continues when screen is off.
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])

            let p = try AVAudioPlayer(contentsOf: silenceURL)
            p.numberOfLoops = -1  // infinite
            p.volume = 0.0
            p.prepareToPlay()
            p.play()
            player = p

            AppLogger.alarm.info("BackgroundKeepAlive: started")
        } catch {
            AppLogger.alarm.error("BackgroundKeepAlive: start failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Stop silent audio and release the audio session.
    func stop() {
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        AppLogger.alarm.info("BackgroundKeepAlive: stopped")
    }

    // MARK: - Silence generation

    /// Create a 1-second silent CAF at `silenceURL` using AVAudioFile.
    /// Same technique as MorningAudioRenderer.writeAsCAF — writes a
    /// zeroed PCM buffer into a CAF container.
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
