import AlarmKit
import AppIntents
import Foundation

/// Handles the "Stop" button on the AlarmKit lock-screen alert.
///
/// This intent is a **fallback path** — the primary affirmation playback
/// runs through `AlarmKitScheduler.handleFire`, which cancels the system
/// alarm immediately and starts affirmations. If the app process was
/// killed (no `handleFire`), the lock-screen Stop button triggers this
/// intent, which foregrounds the app so `checkPendingMorningPlayback`
/// can play affirmations from a reliable audio session context.
///
/// Audio playback is NOT attempted here (the sandboxed intent context
/// fails frequently on iOS 26.3.1). Instead we write a handoff key and
/// let the foreground retry handle it.
struct StopAndPlayClosingIntent: LiveActivityIntent {

    // MARK: - Intent metadata
    //
    // Protocol requirements are declared `{ get }`; `let` satisfies them
    // and keeps the static shared state concurrency-safe under Swift 6.

    static let title: LocalizedStringResource = "Stop"
    static let description = IntentDescription("Stop the alarm and play the closing message.")

    static let openAppWhenRun: Bool = true

    // MARK: - Parameters

    @Parameter(title: "alarmID")
    var alarmID: String

    // MARK: - Init

    init() {
        self.alarmID = ""
    }

    init(alarmID: UUID) {
        self.alarmID = alarmID.uuidString
    }

    // MARK: - Perform

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else { return .result() }

        DiagnosticsLog.shared.log("intent", "stop perform \(uuid.uuidString.prefix(8))")

        try? AlarmManager.shared.cancel(id: uuid)

        UserDefaults.standard.set(uuid.uuidString, forKey: PendingPlayback.userDefaultsKey)

        return .result()
    }
}

// MARK: - Handoff key

/// Namespaces the `UserDefaults` key shared between the intent and
/// `AffirmationAlarmApp.checkPendingMorningPlayback`. Extracting the
/// string into a single named constant prevents drift.
enum PendingPlayback {
    static let userDefaultsKey = "pendingMorningPlayback"
}
