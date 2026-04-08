import UIKit
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UIGestureRecognizerDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        registerNotificationCategories()
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        installKeyboardDismissGesture()
    }

    // MARK: - Tap-to-dismiss keyboard (app-wide)

    /// Installs a single `UITapGestureRecognizer` on every window so that
    /// tapping anywhere outside a text field resigns the first responder.
    /// `cancelsTouchesInView = false` keeps buttons and other controls
    /// working normally, and the delegate skips taps that land on a
    /// `UIControl` or an already-editing text input.
    private func installKeyboardDismissGesture() {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            for window in scene.windows {
                if window.gestureRecognizers?.contains(where: { $0.name == "keyboardDismissTap" }) == true {
                    continue
                }
                let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardFromWindow))
                tap.name = "keyboardDismissTap"
                tap.cancelsTouchesInView = false
                tap.delegate = self
                window.addGestureRecognizer(tap)
            }
        }
    }

    @objc private func dismissKeyboardFromWindow() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Don't swallow touches on controls (buttons, sliders, toggles) or on
        // UITextInput itself — let them behave normally. The keyboard still
        // dismisses when the user taps anywhere *else* on screen.
        if touch.view is UIControl { return false }
        if let view = touch.view, view.isKind(of: UITextField.self) || view.isKind(of: UITextView.self) {
            return false
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // MARK: - Notification categories

    /// Registers the evening-reflection notification category. Morning
    /// alarms no longer use `UNUserNotification` — they go through
    /// AlarmKit (`AlarmKitScheduler` + `StartMorningRitualIntent`).
    private func registerNotificationCategories() {
        let reflectAction = UNNotificationAction(
            identifier: "REFLECT_ACTION",
            title: "Reflect",
            options: .foreground
        )
        let eveningCategory = UNNotificationCategory(
            identifier: "EVENING_REFLECTION_CATEGORY",
            actions: [reflectAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([eveningCategory])
    }
}

// MARK: - View helper for Enter-to-dismiss on single-line TextFields

extension View {
    /// Press-return-to-dismiss for single-line TextFields. Sets the return
    /// key to "Done" and resigns first responder on submit.
    func dismissKeyboardOnSubmit() -> some View {
        self
            .submitLabel(.done)
            .onSubmit {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
    }
}
