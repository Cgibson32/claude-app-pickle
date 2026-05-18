import MediaPlayer
import UIKit
import AVFoundation

/// Forces the system **media** volume to its maximum before the alarm
/// audio plays, so a user who went to bed with media at 10% still hears
/// the affirmations at full power.
///
/// ## Why this is necessary
///
/// Because we cancel the AlarmKit system alert and drive playback from
/// our own `AVAudioEngine`, playback is governed by the **media volume**
/// slider, not the alarm-volume setting iOS uses for the native alert.
/// If the user's phone is muted (or the media slider is low for any
/// reason — a call, a podcast left paused, a kid's iPad routine) the
/// affirmations will be quiet or inaudible. That's the entire problem
/// we're solving here.
///
/// ## The MPVolumeView technique
///
/// `MPVolumeView` exposes a `UISlider` as a subview whose `.value`
/// setter writes through to the system media volume. It's the standard
/// approach every alarm/meditation/sleep app uses; Apple has not
/// deprecated it through iOS 26. We briefly attach the view to a
/// window off-screen, flip the slider to 1.0, and tear it down.
///
/// ## Volume monitoring
///
/// When an alarm loop is active, the user might press the physical
/// volume-down button. `startMonitoring()` uses KVO on
/// `AVAudioSession.outputVolume` to detect this and re-boost within
/// a few hundred milliseconds. A 500ms cooldown after each boost
/// prevents the KVO callback from re-triggering on our own write.
@MainActor
enum VolumeBooster {

    /// Whether we're actively monitoring for volume changes.
    private(set) static var isMonitoring = false

    /// KVO observation token. Retained while monitoring is active.
    private static var volumeObservation: NSKeyValueObservation?

    /// Timestamp of the last boost — used to suppress the KVO feedback
    /// loop when our own write fires the observer.
    private static var lastBoostTime: Date = .distantPast

    /// Cooldown after a boost before the observer re-boosts. The
    /// MPVolumeView slider write propagates asynchronously; 500ms
    /// absorbs the KVO echo without feeling sluggish on a real
    /// hardware-button press.
    private static let boostCooldown: TimeInterval = 0.5

    // MARK: - Boost

    static let volumeKey = "alarmVolumeLevel"

    /// Set the system media volume to the user's chosen alarm level.
    /// Silently no-ops if we can't find a window to attach the helper
    /// view to — better to fail quietly than crash the alarm path.
    static func boostToMax() {
        guard let window = firstAttachableWindow() else {
            DiagnosticsLog.shared.log("volume", "no window — skipping boost")
            return
        }

        lastBoostTime = Date()

        let helper = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
        helper.alpha = 0.001
        helper.isHidden = false
        window.addSubview(helper)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let slider = helper.subviews.compactMap { $0 as? UISlider }.first
            let level = UserDefaults.standard.float(forKey: VolumeBooster.volumeKey)
            let target: Float = level > 0 ? level : 0.7
            slider?.value = target
            DiagnosticsLog.shared.log("volume", "boosted to \(Int(target * 100))% (slider=\(slider != nil))")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                helper.removeFromSuperview()
            }
        }
    }

    // MARK: - Monitoring

    /// Begin observing volume — but only to log, NOT to re-boost.
    /// The initial boost at alarm start is enough. If the user turns
    /// volume down, they're awake and choosing to lower it — respect that.
    static func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        DiagnosticsLog.shared.log("volume", "monitoring started")
    }

    /// Stop monitoring volume changes. Safe to call even if monitoring
    /// is not active (idempotent).
    static func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        volumeObservation?.invalidate()
        volumeObservation = nil
        DiagnosticsLog.shared.log("volume", "monitoring stopped")
    }

    // MARK: - Private

    /// An `MPVolumeView` only controls system volume once it's in a live
    /// window hierarchy. Walk every connected scene's windows — when the
    /// intent is running or the app is just foregrounding from an alarm,
    /// `keyWindow` on the first scene isn't always populated yet.
    private static func firstAttachableWindow() -> UIWindow? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        return windows.first(where: \.isKeyWindow) ?? windows.first
    }
}
