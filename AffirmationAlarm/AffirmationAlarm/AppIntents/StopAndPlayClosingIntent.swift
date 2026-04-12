import AlarmKit
import AppIntents
import AVFoundation
import Foundation

/// Runs when the user taps the Stop button on the AlarmKit alarm UI.
///
/// Because `.named(_:)` is broken on iOS 26.1, AlarmKit plays `.default`
/// as the wake-up sound. Once the user taps Stop, this intent plays the
/// pre-rendered morning affirmation sequence followed by the closing
/// statement via AVAudioPlayer.
///
/// Flow: `.default` alarm → [tap Stop] → greeting + affirmations → closing → silence
struct StopAndPlayClosingIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop"
    static let description = IntentDescription("Stop the alarm and play the closing message.")
    static let openAppWhenRun: Bool = false

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: UUID) {
        self.alarmID = alarmID.uuidString
    }

    init() {
        self.alarmID = ""
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else { return .result() }

        // Cancel the ringing alarm so .default sound stops immediately.
        try? AlarmManager.shared.cancel(id: uuid)

        let soundsDir = FileManager.default
            .urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sounds")

        let morningURL = soundsDir.appendingPathComponent("morning-\(uuid.uuidString).caf")
        let closingURL = soundsDir.appendingPathComponent("closing-\(uuid.uuidString).caf")

        let hasMorning = FileManager.default.fileExists(atPath: morningURL.path)
        let hasClosing = FileManager.default.fileExists(atPath: closingURL.path)

        guard hasMorning || hasClosing else { return .result() }

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
            AppLogger.alarm.error("StopIntent: audio session failed: \(error.localizedDescription, privacy: .public)")
            return .result()
        }

        if hasMorning {
            await playFile(at: morningURL)
        }

        if hasClosing {
            await playFile(at: closingURL)
        }

        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        return .result()
    }

    /// Play a single audio file to completion. Uses `withExtendedLifetime`
    /// to prevent ARC from releasing the player during the `sleep` await.
    private func playFile(at url: URL) async {
        let player: AVAudioPlayer
        do {
            player = try AVAudioPlayer(contentsOf: url)
        } catch {
            AppLogger.alarm.error("StopIntent: AVAudioPlayer init failed for \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return
        }

        player.volume = 1.0
        player.prepareToPlay()
        guard player.play() else {
            AppLogger.alarm.error("StopIntent: play() returned false for \(url.lastPathComponent, privacy: .public)")
            return
        }

        try? await Task.sleep(for: .seconds(player.duration + 0.3))
        withExtendedLifetime(player) {}
    }
}
