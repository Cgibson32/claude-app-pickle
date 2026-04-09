import Foundation

/// App-wide `Notification.Name` constants used to bridge external events
/// (evening-reflection `UNUserNotification` taps) into SwiftUI state via
/// `NotificationCenter`.
///
/// Note: the previous `didTapAlarmNotification` name was removed along with
/// the in-app affirmation sequence view. Alarm stop/snooze taps now run
/// AlarmKit App Intents directly (`StopAndPlayClosingIntent`,
/// `SnoozeMorningIntent`) without the app launching, so no notification
/// bridge is needed for that flow anymore.
extension Notification.Name {
    /// Posted by `NotificationDelegate` when the user taps the evening
    /// reflection reminder (still a plain `UNUserNotification`, not an alarm).
    static let didTapEveningReflection = Notification.Name("didTapEveningReflection")
}
