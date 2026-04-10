import AlarmKit
import AppIntents
import AVFoundation
import Foundation

/// Runs when the user taps the Stop button on the AlarmKit alarm UI.
///
/// `openAppWhenRun = false` keeps the app in the background — we don't want
/// the home screen or any sequence view to present.
///
/// Because `.named(_:)` is broken on iOS 26.1 (AlarmKit silently ignores ALL
/// custom sound files), AlarmKit plays `.default` as the wake-up sound.
/// Once the user taps Stop, THIS intent plays the pre-rendered morning
/// affirmation sequence (`morning-<alarmID>.caf`) followed by the closing
/// statement (`closing-<alarmID>.caf`) via AVAudioPlayer.
///
/// The user hears:
///   `.default` alarm → [taps Stop] → greeting + affirmations → closing → silence
///
/// If no rendered files exist (offline first run, etc.) the intent no-ops
/// gracefully and the alarm just dismisses silently.
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

        // Configure an explicit playback session so we're audible even after
        // AlarmKit's session has been torn down. `.spokenAudio` is the correct
        // mode for voice prompts — it ducks other audio and uses the spoken
        // content routing path.
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            return .result()
        }

        // 1. Morning sequence: greeting + affirmations (~15-25s)
        if hasMorning {
            await playFile(at: morningURL)
        }

        // 2. Closing statement (~3s)
        if hasClosing {
            await playFile(at: closingURL)
        }

        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        return .result()
    }

    /// Play a single audio file to completion. Uses `withExtendedLifetime` to
    /// prevent ARC from releasing the player during the `sleep` await — without
    /// this, Swift's optimizer can release the local `let` the moment its last
    /// observable use (`player.play()`) completes, cutting audio mid-playback
    /// in release builds.
    private func playFile(at url: URL) async {
        let player: AVAudioPlayer
        do {
            player = try AVAudioPlayer(contentsOf: url)
        } catch {
            return
        }
        player.prepareToPlay()
        let duration = player.duration
        player.play()
        try? await Task.sleep(for: .seconds(duration + 0.15))
        withExtendedLifetime(player) {}
    }
}
