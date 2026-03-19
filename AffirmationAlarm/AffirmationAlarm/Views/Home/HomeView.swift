import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: [SortDescriptor(\Alarm.hour), SortDescriptor(\Alarm.minute)]) private var alarms: [Alarm]
    @State private var todayAffirmations: [Affirmation] = []
    @State private var showAffirmationSequence = false
    @State private var appeared = false

    private var profile: UserProfile? { profiles.first }

    private var nextAlarm: Alarm? {
        alarms
            .filter(\.isEnabled)
            .compactMap { alarm -> (Alarm, Date)? in
                guard let date = alarm.nextFireDate else { return nil }
                return (alarm, date)
            }
            .sorted { $0.1 < $1.1 }
            .first?.0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Greeting
                        if let profile {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(greetingText)
                                        .font(AppTheme.title3)
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text(profile.name)
                                        .font(AppTheme.largeTitle)
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Spacer()
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                        }

                        // Next alarm card
                        NextAlarmCard(alarm: nextAlarm)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)

                        // Today's affirmations
                        TodayAffirmationsCard(affirmations: todayAffirmations)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)

                        // Quick actions
                        HStack(spacing: 12) {
                            NavigationLink {
                                AlarmListView()
                            } label: {
                                quickActionButton(icon: "alarm", title: "Alarms")
                            }

                            NavigationLink {
                                FavoritesView()
                            } label: {
                                quickActionButton(icon: "heart.fill", title: "Favorites")
                            }

                            NavigationLink {
                                SettingsView()
                            } label: {
                                quickActionButton(icon: "gearshape", title: "Settings")
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)

                        // Preview button
                        Button {
                            HapticService.medium()
                            showAffirmationSequence = true
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Preview Affirmation Sequence")
                            }
                            .font(AppTheme.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.strokeLight, lineWidth: 1)
                            )
                        }
                        .opacity(appeared ? 1 : 0)
                    }
                    .padding()
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showAffirmationSequence) {
                AffirmationSequenceView()
            }
        }
        .onAppear {
            loadAffirmations()
            refreshCache()
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Helpers

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning," }
        if hour < 17 { return "Good Afternoon," }
        return "Good Evening,"
    }

    private func quickActionButton(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
            Text(title)
                .font(AppTheme.caption)
        }
        .foregroundColor(AppTheme.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
        )
    }

    private func loadAffirmations() {
        todayAffirmations = AffirmationCacheService.shared.getTodayAffirmations(modelContext: modelContext)
    }

    private func refreshCache() {
        guard let profile else { return }
        Task {
            await AffirmationCacheService.shared.prefetchIfNeeded(
                modelContext: modelContext,
                profile: profile
            )
            loadAffirmations()
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [UserProfile.self, Alarm.self, Affirmation.self], inMemory: true)
}
