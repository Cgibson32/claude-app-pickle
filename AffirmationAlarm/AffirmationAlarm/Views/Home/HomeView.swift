import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: [SortDescriptor(\Alarm.hour), SortDescriptor(\Alarm.minute)]) private var alarms: [Alarm]
    @State private var todayAffirmations: [Affirmation] = []
    @State private var showAffirmationSequence = false
    @State private var appeared = false
    @State private var currentStreak: Int = 0
    @State private var todayIntention: DailyIntention?

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

                                // Streak badge
                                if currentStreak > 0 {
                                    HStack(spacing: 6) {
                                        Image(systemName: "flame.fill")
                                            .foregroundColor(AppTheme.sunsetOrange)
                                        Text("\(currentStreak)")
                                            .font(AppTheme.headline)
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(AppTheme.cardBackground))
                                }
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                        }

                        // Today's intention
                        if let intention = todayIntention {
                            HStack(spacing: 10) {
                                Image(systemName: "scope")
                                    .foregroundColor(AppTheme.gold)
                                Text(intention.text)
                                    .font(AppTheme.subheadline)
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppTheme.cardBackground)
                            )
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
                                JournalView()
                            } label: {
                                quickActionButton(icon: "book.fill", title: "Journal")
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
            loadData()
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

    private func loadData() {
        todayAffirmations = AffirmationCacheService.shared.getTodayAffirmations(modelContext: modelContext)
        currentStreak = StreakService.shared.currentStreak(modelContext: modelContext)
        loadTodayIntention()
    }

    private func loadTodayIntention() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        let descriptor = FetchDescriptor<DailyIntention>(
            predicate: #Predicate { intention in
                intention.date >= startOfDay && intention.date < endOfDay
            },
            sortBy: [SortDescriptor(\DailyIntention.date, order: .reverse)]
        )

        todayIntention = (try? modelContext.fetch(descriptor))?.first
    }

    private func refreshCache() {
        guard let profile else { return }
        Task {
            await AffirmationCacheService.shared.prefetchIfNeeded(
                modelContext: modelContext,
                profile: profile
            )
            loadData()
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [UserProfile.self, Alarm.self, Affirmation.self], inMemory: true)
}
