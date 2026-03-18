import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: [SortDescriptor(\Alarm.hour), SortDescriptor(\Alarm.minute)]) private var alarms: [Alarm]
    @State private var todayAffirmations: [Affirmation] = []
    @State private var showAffirmationSequence = false

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
                                        .font(.title3)
                                        .foregroundColor(.white.opacity(0.7))
                                    Text(profile.name)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                        }

                        // Next alarm card
                        NextAlarmCard(alarm: nextAlarm)

                        // Today's affirmations
                        TodayAffirmationsCard(affirmations: todayAffirmations)

                        // Quick actions
                        HStack(spacing: 12) {
                            NavigationLink {
                                AlarmListView()
                            } label: {
                                quickActionButton(icon: "alarm", title: "Alarms")
                            }

                            NavigationLink {
                                SettingsView()
                            } label: {
                                quickActionButton(icon: "gearshape", title: "Settings")
                            }
                        }

                        // Preview button
                        Button {
                            showAffirmationSequence = true
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Preview Affirmation Sequence")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
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
                .font(.title2)
            Text(title)
                .font(.caption)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.12))
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
