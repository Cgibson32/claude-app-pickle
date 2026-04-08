import Foundation

/// App-wide `Notification.Name` constants used to bridge external events
/// (AlarmKit App Intents, evening-reflection `UNUserNotification` taps) into
/// SwiftUI state via `NotificationCenter`.
extension Notification.Name {
    /// Posted by `StartMorningRitualIntent.perform()` when the user taps the
    /// AlarmKit alarm's stop button and the app is launched into the foreground.
    static let didTapAlarmNotification = Notification.Name("didTapAlarmNotification")

    /// Posted by `NotificationDelegate` when the user taps the evening
    /// reflection reminder (still a plain `UNUserNotification`, not an alarm).
    static let didTapEveningReflection = Notification.Name("didTapEveningReflection")
}
