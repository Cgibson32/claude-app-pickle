import AlarmKit
import AppIntents
import AVFoundation
import Foundation

/// Runs when the user taps the Stop button on the AlarmKit alarm UI.
///
/// `openAppWhenRun = false` keeps the app in the background — we don't want
/// the home screen or any sequence view to present. The intent loads the
/// pre-rendered `closing-<alarmID>.wav` (written alongside `morning-*.wav`
/// by `MorningAudioRenderer`) and plays it to completion via an
/// `AVAudioPlayer`, then returns.
///
/// AlarmKit cuts the main morning audio as soon as Stop is tapped, so our
/// closing plays AFTER that cut. The user hears a clean transition:
/// `[affirmation cut mid-word] → [closing statement] → silence`.
///
/// If no rendered closing exists (offline first run, snooze follow-up alarm
/// with its own UUID, etc.) the intent no-ops gracefully and the alarm
/// just dismisses silently — which is the correct fallback.
struct StopAndPlayClosingIntent: LiveActivityIntent {
    // See `SnoozeMorningIntent` for the rationale — these are `static let`
    // (not `var`) to satisfy Swift 6 strict concurrency while still
    // conforming to the `LiveActivityIntent` protocol's `{ get }`
    // requirements for `title`, `description`, and `openAppWhenRun`.
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

        // Belt-and-suspenders: ask AlarmKit to cancel the alarm too. In the
        // common case AlarmKit has already cut the sound because Stop was
        // tapped, but if iOS routed the intent without cancelling first
        // this ensures the ring doesn't keep playing on top of our closing.
        try? AlarmManager.shared.cancel(id: uuid)

        let closingURL = FileManager.default
            .urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sounds/closing-\(uuid.uuidString).wav")

        guard FileManager.default.fileExists(atPath: closingURL.path) else {
            return .result()
        }

        // Configure an explicit playback session so we're audible even if
        // AlarmKit's session has already been torn down. `.spokenAudio` is
        // the correct category for a short voice prompt.
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            return .result()
        }

        let player: AVAudioPlayer
        do {
            player = try AVAudioPlayer(contentsOf: closingURL)
        } catch {
            return .result()
        }

        player.prepareToPlay()
        let duration = player.duration
        player.play()

        // Wait for the closing to finish. Sleep a hair past the known file
        // duration rather than wiring up an AVAudioPlayerDelegate continuation
        // — simpler, and the duration is fixed at render time.
        try? await Task.sleep(for: .seconds(duration + 0.15))

        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        return .result()
    }
}
