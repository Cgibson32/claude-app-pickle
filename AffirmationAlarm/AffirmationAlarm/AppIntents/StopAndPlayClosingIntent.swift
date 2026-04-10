import AlarmKit
import AppIntents
import AVFoundation
import Foundation

/// Runs when the user taps the Stop button on the AlarmKit alarm UI.
///
/// Because `.named(_:)` is broken on iOS 26.1, AlarmKit plays `.default`
/// as the wake-up sound. Once the user taps Stop, THIS intent plays the
/// pre-rendered morning affirmation sequence followed by the closing
/// statement via AVAudioPlayer.
///
/// The user hears:
///   `.default` alarm → [taps Stop] → greeting + affirmations → closing → silence
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
        let log = { (msg: String) in
            Task { @MainActor in DiagnosticLog.shared.log("StopIntent: \(msg)") }
        }

        log("perform() called, alarmID=\(alarmID)")

        guard let uuid = UUID(uuidString: alarmID) else {
            log("invalid UUID, bailing")
            return .result()
        }

        // Cancel the ringing alarm so .default sound stops immediately.
        do {
            try AlarmManager.shared.cancel(id: uuid)
            log("alarm cancelled OK")
        } catch {
            log("alarm cancel error: \(error.localizedDescription)")
        }

        // Give AlarmKit a moment to fully tear down its audio session
        // before we try to claim the audio route.
        try? await Task.sleep(for: .seconds(0.5))

        let soundsDir = FileManager.default
            .urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sounds")

        let morningURL = soundsDir.appendingPathComponent("morning-\(uuid.uuidString).caf")
        let closingURL = soundsDir.appendingPathComponent("closing-\(uuid.uuidString).caf")

        let hasMorning = FileManager.default.fileExists(atPath: morningURL.path)
        let hasClosing = FileManager.default.fileExists(atPath: closingURL.path)
        log("morning exists: \(hasMorning), closing exists: \(hasClosing)")

        if hasMorning {
            let size = (try? FileManager.default.attributesOfItem(atPath: morningURL.path)[.size] as? Int) ?? 0
            log("morning file size: \(size) bytes")
        }

        guard hasMorning || hasClosing else {
            log("no audio files found, bailing")
            return .result()
        }

        // Configure audio session for playback.
        do {
            let session = AVAudioSession.sharedInstance()
            log("current audio route: \(session.currentRoute.outputs.map { $0.portType.rawValue })")
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true, options: [])
            log("audio session active, category=playback, mode=spokenAudio")
            log("output volume: \(session.outputVolume)")
        } catch {
            log("audio session FAILED: \(error.localizedDescription)")
            return .result()
        }

        // 1. Morning sequence: greeting + affirmations (~15-25s)
        if hasMorning {
            log("playing morning file...")
            let played = await playFile(at: morningURL)
            log("morning playback \(played ? "completed" : "FAILED")")
        }

        // 2. Closing statement (~3s)
        if hasClosing {
            log("playing closing file...")
            let played = await playFile(at: closingURL)
            log("closing playback \(played ? "completed" : "FAILED")")
        }

        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        log("done, audio session deactivated")
        return .result()
    }

    /// Play a single audio file to completion. Returns `true` if playback
    /// started successfully.
    private func playFile(at url: URL) async -> Bool {
        let log = { (msg: String) in
            Task { @MainActor in DiagnosticLog.shared.log("  playFile: \(msg)") }
        }

        let player: AVAudioPlayer
        do {
            player = try AVAudioPlayer(contentsOf: url)
            log("loaded \(url.lastPathComponent), duration=\(String(format: "%.1f", player.duration))s")
        } catch {
            log("AVAudioPlayer init FAILED: \(error.localizedDescription)")
            return false
        }

        player.prepareToPlay()
        let started = player.play()
        log("play() returned \(started)")

        if !started {
            log("play() returned false — audio will not play")
            return false
        }

        let duration = player.duration
        try? await Task.sleep(for: .seconds(duration + 0.3))
        withExtendedLifetime(player) {}
        return true
    }
}
