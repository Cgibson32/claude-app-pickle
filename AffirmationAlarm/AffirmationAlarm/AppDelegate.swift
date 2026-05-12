import Sentry
import UIKit
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UIGestureRecognizerDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureSentryIfAvailable()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        registerNotificationCategories()
        return true
    }

    /// Initialize Sentry crash reporting if a DSN is configured in the
    /// bundle's Info.plist. No-ops silently when the DSN is missing or
    /// still set to the unreplaced `$(SENTRY_DSN)` template — so local
    /// debug builds and CI builds without a Sentry account still run.
    ///
    /// Apple rejects submissions that crash on launch; guarding with a
    /// nil check means a missing `SENTRY_DSN` can never take down the
    /// app. If you want crash reporting, set `SENTRY_DSN` in CodeMagic's
    /// `appstore_credentials` environment group and the pre-archive
    /// script in `codemagic.yaml` will inject it into Info.plist.
    private func configureSentryIfAvailable() {
        guard let dsn = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String,
              !dsn.isEmpty,
              dsn != "$(SENTRY_DSN)" else {
            return
        }
        SentrySDK.start { options in
            options.dsn = dsn
            options.debug = false
            options.tracesSampleRate = 0.1
            options.enableAutoPerformanceTracing = true
            // Scrub any personally-identifying info before sending.
            // We never attach user IDs or device IDs anyway — this is
            // belt-and-suspenders.
            options.beforeSend = { event in
                event.user = nil
                return event
            }
        }
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
    /// AlarmKit via `AlarmKitScheduler` and the `StopAndPlayClosingIntent`
    /// / `SnoozeMorningIntent` pair.
    private func registerNotificationCategories() {
        NotificationDelegate.shared.registerCategories()
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
