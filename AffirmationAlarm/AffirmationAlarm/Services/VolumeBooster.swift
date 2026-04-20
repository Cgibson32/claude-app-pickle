import MediaPlayer
import UIKit

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
/// The double-`DispatchQueue.main.asyncAfter` is not overkill: iOS
/// wires the hidden slider to the real volume state on the next
/// runloop tick, and needs another tick after assignment before the
/// volume change commits — removing the view too early sometimes drops
/// the write on the floor. 50ms + 100ms is the shortest pair that
/// reliably commits across devices.
@MainActor
enum VolumeBooster {
    /// Set the system media volume to 1.0. Silently no-ops if we can't
    /// find a window to attach the helper view to — better to fail
    /// quietly than crash the alarm path over a UI edge case.
    static func boostToMax() {
        guard let window = firstAttachableWindow() else {
            DiagnosticsLog.shared.log("volume", "no window — skipping boost")
            return
        }

        let helper = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
        helper.alpha = 0.001
        helper.isHidden = false
        window.addSubview(helper)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let slider = helper.subviews.compactMap { $0 as? UISlider }.first
            slider?.value = 1.0
            DiagnosticsLog.shared.log("volume", "boosted to max (slider=\(slider != nil))")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                helper.removeFromSuperview()
            }
        }
    }

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
