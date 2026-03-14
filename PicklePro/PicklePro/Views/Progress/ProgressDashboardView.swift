import SwiftUI

struct ProgressDashboardView: View {
    @StateObject private var viewModel = ProgressViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                PickleProColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Streaks
                        HStack(spacing: 12) {
                            StreakCard(
                                icon: "flame.fill",
                                value: viewModel.progressData.consistencyStreak,
                                label: "Day Streak",
                                color: PickleProColors.accent
                            )
                            StreakCard(
                                icon: "book.fill",
                                value: viewModel.progressData.journalingStreak,
                                label: "Journal Streak",
                                color: PickleProColors.teal
                            )
                        }
                        .padding(.horizontal, 24)

                        // Stats Row
                        HStack(spacing: 12) {
                            StatCard(value: "\(viewModel.progressData.totalPlaySessions)", label: "Sessions")
                            StatCard(value: "\(viewModel.progressData.totalJournalEntries)", label: "Entries")
                            StatCard(value: "\(viewModel.progressData.focusedPlaySessions)", label: "Focused")
                        }
                        .padding(.horizontal, 24)

                        // Process Metrics
                        VStack(spacing: 12) {
                            PPSectionHeader(title: "Process Metrics")
                                .padding(.horizontal, 24)

                            PPCard {
                                VStack(spacing: 16) {
                                    MetricRow(
                                        label: "Patience Score",
                                        value: viewModel.progressData.patienceScore,
                                        color: PickleProColors.teal
                                    )
                                    MetricRow(
                                        label: "Confidence Score",
                                        value: viewModel.progressData.confidenceScore,
                                        color: PickleProColors.gold
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        // Skill Progress
                        VStack(spacing: 12) {
                            PPSectionHeader(title: "Skill Progress")
                                .padding(.horizontal, 24)

                            ForEach(viewModel.progressData.skillProgress) { skill in
                                SkillProgressRow(skill: skill)
                                    .padding(.horizontal, 24)
                            }
                        }

                        // Weekly Mood
                        VStack(spacing: 12) {
                            PPSectionHeader(title: "Weekly Mood")
                                .padding(.horizontal, 24)

                            PPCard {
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Average")
                                            .font(PickleProTypography.subheadline)
                                            .foregroundColor(PickleProColors.textSecondary)
                                        Spacer()
                                        Text(String(format: "%.1f", viewModel.averageMoodScore) + "/5")
                                            .font(PickleProTypography.headline)
                                            .foregroundColor(PickleProColors.accent)
                                    }

                                    HStack(spacing: 4) {
                                        ForEach(viewModel.progressData.weeklyMoodTrend.reversed()) { mood in
                                            VStack(spacing: 6) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(moodColor(score: mood.score))
                                                    .frame(height: CGFloat(mood.score) * 16)

                                                Text(dayAbbreviation(mood.date))
                                                    .font(PickleProTypography.caption)
                                                    .foregroundColor(PickleProColors.textTertiary)
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                    }
                                    .frame(height: 100, alignment: .bottom)
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        // Encouragement
                        PPQuoteCard(
                            quote: "Growth compounds. Every session, every journal entry, every intention — it all adds up.",
                            attribution: "PicklePro"
                        )
                        .padding(.horizontal, 24)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func moodColor(score: Int) -> Color {
        switch score {
        case 5: return PickleProColors.accent
        case 4: return PickleProColors.teal
        case 3: return PickleProColors.info
        case 2: return PickleProColors.warning
        default: return PickleProColors.error
        }
    }

    private func dayAbbreviation(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(2))
    }
}

struct StreakCard: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text("\(value)")
                .font(PickleProTypography.title)
                .foregroundColor(.white)

            Text(label)
                .font(PickleProTypography.caption)
                .foregroundColor(PickleProColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(PickleProColors.cardBackground)
        .cornerRadius(16)
    }
}

struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(PickleProTypography.title3)
                .foregroundColor(.white)
            Text(label)
                .font(PickleProTypography.caption)
                .foregroundColor(PickleProColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(PickleProColors.cardBackground)
        .cornerRadius(12)
    }
}

struct MetricRow: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(PickleProTypography.subheadline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(value))%")
                    .font(PickleProTypography.headline)
                    .foregroundColor(color)
            }
            PPProgressBar(progress: value / 100, color: color)
        }
    }
}

struct SkillProgressRow: View {
    let skill: SkillProgress

    var trendIcon: String {
        switch skill.trend {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var trendColor: Color {
        switch skill.trend {
        case .improving: return PickleProColors.success
        case .stable: return PickleProColors.info
        case .declining: return PickleProColors.error
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(skill.skill)
                        .font(PickleProTypography.subheadline)
                        .foregroundColor(.white)

                    Image(systemName: trendIcon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(trendColor)
                }

                PPProgressBar(progress: skill.progress / 100, color: trendColor)
            }

            Text("\(Int(skill.progress))%")
                .font(PickleProTypography.headline)
                .foregroundColor(trendColor)
                .frame(width: 50)
        }
        .padding(14)
        .background(PickleProColors.cardBackground)
        .cornerRadius(12)
    }
}
