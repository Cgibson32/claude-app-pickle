import AlarmKit
import AppIntents
import Foundation

/// Runs when the user taps the Stop button on the AlarmKit alarm UI.
///
/// Cancels the alarm and delegates audio playback to `AlarmAudioPlayer`.
/// If the auto-play observer already played (or is playing) for this
/// alarm, the actor returns `.alreadyPlaying` / `.alreadyPlayed` and
/// this intent becomes a simple cancel — no double audio.
///
/// If the app was force-quit (observer dead), this intent is the ONLY
/// playback path. It still works because `LiveActivityIntent.perform()`
/// runs even when the app isn't in memory.
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

        try? AlarmManager.shared.cancel(id: uuid)

        // Flag for foreground fallback: iOS 26.1 opens the app on
        // slide-to-stop despite openAppWhenRun = false. If the actor
        // can't play from this sandboxed intent context, RootView's
        // scenePhase observer picks up the flag and plays from foreground.
        UserDefaults.standard.set(uuid.uuidString, forKey: "pendingMorningPlayback")

        // Try background playback — actor deduplicates if both paths fire
        _ = await AlarmAudioPlayer.shared.playMorningAndClosing(for: uuid)

        return .result()
    }
}
