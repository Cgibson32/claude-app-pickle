import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var userService: UserService
    @State private var showBeforePlay = false
    @State private var showAfterPlay = false
    @State private var showAICoach = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.greeting)
                            .font(PickleProTypography.subheadline)
                            .foregroundColor(PickleProColors.textSecondary)

                        HStack(spacing: 0) {
                            Text(userService.profile.name.isEmpty ? "Player" : userService.profile.name)
                                .font(PickleProTypography.title)
                                .foregroundColor(.white)
                            Text(" \u{1F3D3}")
                                .font(.system(size: 24))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // Streak Badge
                    HStack(spacing: 12) {
                        PPStreakBadge(count: userService.profile.streakDays, label: "Day Streak")
                        PPStreakBadge(count: userService.profile.journalStreak, label: "Journal Streak")
                        PPStreakBadge(count: userService.profile.totalSessions, label: "Sessions")
                    }
                    .padding(.horizontal, 24)

                    // Daily Inspiration
                    PPQuoteCard(quote: viewModel.quote)
                        .padding(.horizontal, 24)
                        .onTapGesture { viewModel.refreshQuote() }

                    // Today's Intention Card
                    PPAccentCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Today's Intention")
                                    .font(PickleProTypography.headline)
                                    .foregroundColor(PickleProColors.accent)
                                Spacer()
                                Image(systemName: "flame.fill")
                                    .foregroundColor(PickleProColors.accent)
                            }

                            IntentionRow(
                                icon: "target",
                                label: "Performance Focus",
                                value: viewModel.dailyFocus.performanceIntention,
                                color: PickleProColors.accent
                            )

                            IntentionRow(
                                icon: "brain.head.profile",
                                label: "Mental Cue",
                                value: viewModel.dailyFocus.mentalIntention,
                                color: PickleProColors.teal
                            )

                            IntentionRow(
                                icon: "sun.max.fill",
                                label: "Joy Intention",
                                value: viewModel.dailyFocus.joyIntention,
                                color: PickleProColors.gold
                            )

                            IntentionRow(
                                icon: "lightbulb.fill",
                                label: "Skill Focus",
                                value: viewModel.dailyFocus.skillFocus,
                                color: PickleProColors.info
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // Quick Actions
                    VStack(spacing: 12) {
                        PPSectionHeader(title: "Quick Actions")
                            .padding(.horizontal, 24)

                        PPIconButton(
                            icon: "sun.max.fill",
                            title: "Before I Play",
                            subtitle: "Set your intention and mindset",
                            action: { showBeforePlay = true }
                        )
                        .padding(.horizontal, 24)

                        PPIconButton(
                            icon: "moon.fill",
                            title: "After I Played",
                            subtitle: "Reflect and learn from your session",
                            action: { showAfterPlay = true }
                        )
                        .padding(.horizontal, 24)

                        PPIconButton(
                            icon: "sparkles",
                            title: "AI Coach Insights",
                            subtitle: "Personalized coaching for you",
                            action: { showAICoach = true }
                        )
                        .padding(.horizontal, 24)
                    }

                    // Today's Skill Spotlight
                    VStack(spacing: 12) {
                        PPSectionHeader(title: "Today's Skill Spotlight")
                            .padding(.horizontal, 24)

                        SkillSpotlightCard(skill: MockDataService.skills[0])
                            .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(PickleProColors.background)
            .sheet(isPresented: $showBeforePlay) {
                BeforePlayView()
            }
            .sheet(isPresented: $showAfterPlay) {
                PostPlayReflectionView()
            }
            .sheet(isPresented: $showAICoach) {
                AICoachView()
            }
        }
    }
}

struct IntentionRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15))
                .cornerRadius(7)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(PickleProTypography.caption)
                    .foregroundColor(PickleProColors.textTertiary)
                Text(value)
                    .font(PickleProTypography.callout)
                    .foregroundColor(.white)
            }
        }
    }
}

struct SkillSpotlightCard: View {
    let skill: Skill

    var body: some View {
        NavigationLink(destination: SkillDetailView(skill: skill)) {
            PPCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: skill.icon)
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: skill.category.color))

                        Text(skill.title)
                            .font(PickleProTypography.headline)
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(PickleProColors.textTertiary)
                    }

                    Text(String(skill.explanation.prefix(120)) + "...")
                        .font(PickleProTypography.subheadline)
                        .foregroundColor(PickleProColors.textSecondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        ForEach(skill.mentalCues.prefix(2), id: \.self) { cue in
                            Text(cue)
                                .font(PickleProTypography.caption)
                                .foregroundColor(Color(hex: skill.category.color))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: skill.category.color).opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
}
