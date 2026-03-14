import SwiftUI

@main
struct PickleProApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var subscriptionService = SubscriptionService()
    @StateObject private var userService = UserService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(subscriptionService)
                .environmentObject(userService)
                .preferredColorScheme(.dark)
        }
    }
}
