import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \Alarm.hour) private var alarms: [Alarm]
    @Query private var completions: [SequenceCompletion]
    @State private var showPreview = false

    private var profile: UserProfile? { profiles.first }
    private var todayCompleted: Bool {
        completions.contains { AppDateFormatters.isToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground(style: .sunrise)

                ScrollView {
                    VStack(spacing: AppTheme.spacingXl) {
                        // Greeting
                        greetingSection

                        // Next alarm card
                        NextAlarmCard(alarms: alarms)

                        // Today's progress
                        if let profile {
                            TodayProgressCard(
                                completed: todayCompleted,
                                affirmationCount: profile.affirmationCount
                            )
                        }

                        // Quick actions
                        quickActionsGrid

                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, AppTheme.spacingXl)
                    .padding(.top, AppTheme.spacingLg)
                }

                // Floating action button
                VStack {
                    Spacer()
                    Button {
                        HapticService.medium()
                        showPreview = true
                    } label: {
                        HStack(spacing: AppTheme.spacingSm) {
                            Image(systemName: "play.fill")
                            Text("Preview")
                                .font(AppTheme.headline)
                        }
                        .foregroundStyle(AppTheme.charcoalBlue)
                        .padding(.horizontal, AppTheme.spacingXxl)
                        .padding(.vertical, AppTheme.spacingLg)
                        .background(AppTheme.gold)
                        .clipShape(Capsule())
                        .shadow(color: AppTheme.gold.opacity(0.4), radius: 16, y: 8)
                    }
                    .buttonStyle(.bounce)
                    .accessibilityLabel("Preview affirmation sequence")
                    .padding(.bottom, AppTheme.spacingXl)
                }
            }
            .preferredColorScheme(.dark)
            .fullScreenCover(isPresented: $showPreview) {
                AffirmationSequenceView()
            }
        }
    }

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeOfDayGreeting)
                    .font(AppTheme.title2)
                    .foregroundStyle(AppTheme.textPrimary)
                if let name = profile?.name, !name.isEmpty {
                    Text(name)
                        .font(AppTheme.largeTitle)
                        .foregroundStyle(AppTheme.gold)
                }
            }
            Spacer()
            Text(timeOfDayEmoji)
                .font(.system(size: 40))
        }
    }

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Rise & shine"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Sweet dreams"
        }
    }

    private var timeOfDayEmoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "\u{1F31E}"
        case 12..<17: return "\u{2600}\u{FE0F}"
        case 17..<21: return "\u{1F305}"
        default: return "\u{1F319}"
        }
    }

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacingMd) {
            NavigationLink {
                AlarmListView()
            } label: {
                QuickActionCard(icon: "alarm.fill", title: "Alarms", color: AppTheme.sunsetOrange)
            }

            NavigationLink {
                FavoritesView()
            } label: {
                QuickActionCard(icon: "heart.fill", title: "Favorites", color: Color(hex: "E85D75"))
            }

            NavigationLink {
                JournalView()
            } label: {
                QuickActionCard(icon: "book.fill", title: "Journal", color: AppTheme.warmAmber)
            }

            NavigationLink {
                SettingsView()
            } label: {
                QuickActionCard(icon: "gearshape.fill", title: "Settings", color: AppTheme.textSecondary)
            }
        }
        .buttonStyle(.bounce)
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.spacingMd) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            Text(title)
                .font(AppTheme.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingXl)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

// MARK: - Today Progress Card

struct TodayProgressCard: View {
    let completed: Bool
    let affirmationCount: Int

    var body: some View {
        HStack(spacing: AppTheme.spacingLg) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(AppTheme.strokeLight, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: completed ? 1.0 : 0.0)
                    .stroke(AppTheme.gold, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Image(systemName: completed ? "checkmark" : "sun.max.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(completed ? AppTheme.gold : AppTheme.textTertiary)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(completed ? "Complete!" : "Today's Affirmations")
                    .font(AppTheme.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(completed ? "\(affirmationCount) affirmations spoken" : "Tap Preview to begin")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
    }
}
