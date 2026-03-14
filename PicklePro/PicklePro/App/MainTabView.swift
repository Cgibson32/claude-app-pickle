import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text("Today")
                }
                .tag(AppState.AppTab.home)

            SkillLibraryView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Skills")
                }
                .tag(AppState.AppTab.skills)

            JournalView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Journal")
                }
                .tag(AppState.AppTab.journal)

            ProgressDashboardView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(AppState.AppTab.progress)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(AppState.AppTab.profile)
        }
        .tint(PickleProColors.accent)
    }
}
