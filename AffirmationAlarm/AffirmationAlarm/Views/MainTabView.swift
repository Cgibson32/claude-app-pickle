import SwiftUI

/// Three-tab shell shown post-onboarding. Replaces the old in-Home
/// `quickActionsGrid` of NavigationLinks with persistent tab navigation —
/// a tap reaches any top-level area from anywhere in the app, matching
/// standard iOS patterns users already know.
///
/// Each tab owns its own `NavigationStack` so deep navigation (e.g.
/// Settings → Profile → Voice) stays scoped to its tab and doesn't bleed
/// across tab switches.
struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "sun.max.fill")
            }

            NavigationStack {
                AlarmListView()
            }
            .tabItem {
                Label("Alarms", systemImage: "alarm.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(AppTheme.gold)
        .preferredColorScheme(.dark)
    }
}
