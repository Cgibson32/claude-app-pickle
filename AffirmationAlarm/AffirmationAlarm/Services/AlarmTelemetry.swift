import Foundation
import UIKit

/// Thin structured-event wrapper over `DiagnosticsLog`. Every important
/// phase boundary in the alarm pipeline calls `AlarmTelemetry.event(...)`
/// so a single scan of the on-device log reveals the full lifecycle:
///
///     scheduled → fire → ringingShown → stop → renderStart → renderComplete
///                                     → playStart → playComplete → cleanup
///
/// Each event records `phase`, short `alarmID`, optional `elapsedMs`, the
/// current app state (`active` / `inactive` / `background`), and whether
/// Sleep Mode was active. Keeping the format mechanical makes it grep-able
/// when a user sends their diagnostics export.
///
/// A future external breadcrumb sink (Sentry, OSLog signposts) plugs in
/// at `emitExternal` without touching call sites.
enum AlarmTelemetry {

    /// Named phase boundary. Add new cases freely — `rawValue` is what
    /// shows up in the diagnostics log, so pick a short kebab-friendly
    /// string.
    enum Phase: String {
        case scheduled
        case schedulingFailed = "scheduling-failed"
        case fire
        case fireNoRender = "fire-no-render"
        case fireBackgrounded = "fire-backgrounded"
        case ringingShown = "ringing-shown"
        case ringingDismissed = "ringing-dismissed"
        case ringingTimeout = "ringing-timeout"
        case stopPressed = "stop-pressed"
        case snoozePressed = "snooze-pressed"
        case snoozeFollowUpScheduled = "snooze-follow-up-scheduled"
        case snoozeFollowUpFailed = "snooze-follow-up-failed"
        case snoozeRenderStart = "snooze-render-start"
        case snoozeRenderComplete = "snooze-render-complete"
        case snoozeRenderFailed = "snooze-render-failed"
        case playStart = "play-start"
        case playComplete = "play-complete"
        case loopStart = "loop-start"
        case loopStop = "loop-stop"
        case escalation = "escalation"
        case fallbackScheduled = "fallback-scheduled"
        case volumeReboosted = "volume-reboosted"
        case missedAlarmDetected = "missed-alarm-detected"
        case lastFireRecorded = "last-fire-recorded"
    }

    /// Record an event. Safe to call from any isolation context — emission
    /// hops to MainActor so the app-state read is deterministic.
    static func event(
        _ phase: Phase,
        alarmID: UUID? = nil,
        elapsedMs: Int? = nil,
        extra: String? = nil
    ) {
        Task { @MainActor in
            let appState = appStateString()
            let sleepActive = AlarmKitScheduler.shared.isSleepModeActive
            emit(
                phase: phase,
                alarmID: alarmID,
                elapsedMs: elapsedMs,
                extra: extra,
                appState: appState,
                sleepActive: sleepActive
            )
        }
    }

    /// Synchronous variant for MainActor call sites that already hold
    /// the latest state — avoids an extra Task hop.
    @MainActor
    static func eventSync(
        _ phase: Phase,
        alarmID: UUID? = nil,
        elapsedMs: Int? = nil,
        extra: String? = nil
    ) {
        emit(
            phase: phase,
            alarmID: alarmID,
            elapsedMs: elapsedMs,
            extra: extra,
            appState: appStateString(),
            sleepActive: AlarmKitScheduler.shared.isSleepModeActive
        )
    }

    // MARK: - Emission

    private static func emit(
        phase: Phase,
        alarmID: UUID?,
        elapsedMs: Int?,
        extra: String?,
        appState: String,
        sleepActive: Bool
    ) {
        var parts: [String] = [phase.rawValue]
        if let alarmID {
            parts.append("id=\(alarmID.uuidString.prefix(8))")
        }
        if let elapsedMs {
            parts.append("elapsed=\(elapsedMs)ms")
        }
        parts.append("app=\(appState)")
        parts.append("sleep=\(sleepActive ? "y" : "n")")
        if let extra, !extra.isEmpty {
            parts.append(extra)
        }
        let message = parts.joined(separator: " ")
        DiagnosticsLog.shared.log("telemetry", message)
        emitExternal(phase: phase, message: message)
    }

    /// Stub for external sinks (Sentry breadcrumbs, OSLog signposts). Kept
    /// as a no-op for now; flipping to live just requires wiring this one
    /// function.
    private static func emitExternal(phase: Phase, message: String) {
        // Intentional no-op until an external sink is wired up.
    }

    @MainActor
    private static func appStateString() -> String {
        switch UIApplication.shared.applicationState {
        case .active: return "active"
        case .inactive: return "inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }
}
