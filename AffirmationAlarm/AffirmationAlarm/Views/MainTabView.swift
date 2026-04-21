import SwiftUI

/// Four-tab shell shown post-onboarding. Each tab owns its own
/// `NavigationStack` so deep navigation stays scoped per tab.
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
                AffirmationsTabView()
            }
            .tabItem {
                Label("Affirmations", systemImage: "sparkles")
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
