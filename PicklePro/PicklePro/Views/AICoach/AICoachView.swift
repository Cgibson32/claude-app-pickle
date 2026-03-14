import SwiftUI

struct AICoachView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var insights = MockDataService.coachInsights
    @State private var showChat = false

    var body: some View {
        NavigationStack {
            ZStack {
                PickleProColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // AI Coach Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(PickleProColors.accent.opacity(0.1))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "sparkles")
                                    .font(.system(size: 32))
                                    .foregroundColor(PickleProColors.accent)
                            }

                            Text("AI Coach")
                                .font(PickleProTypography.title)
                                .foregroundColor(.white)

                            Text("Personalized insights based on your journey")
                                .font(PickleProTypography.subheadline)
                                .foregroundColor(PickleProColors.textSecondary)
                        }
                        .padding(.top, 20)

                        // Chat Button
                        PPButton(title: "Chat with Coach", style: .primary) {
                            showChat = true
                        }
                        .padding(.horizontal, 24)

                        // Insights
                        VStack(spacing: 12) {
                            PPSectionHeader(title: "Recent Insights")
                                .padding(.horizontal, 24)

                            ForEach(insights) { insight in
                                InsightCard(insight: insight)
                                    .padding(.horizontal, 24)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(PickleProColors.accent)
                }
            }
            .sheet(isPresented: $showChat) {
                AIChatView()
            }
        }
    }
}

struct InsightCard: View {
    let insight: AICoachInsight

    var body: some View {
        PPCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    InsightTypeBadge(type: insight.type)
                    Spacer()
                    if !insight.isRead {
                        Circle()
                            .fill(PickleProColors.accent)
                            .frame(width: 8, height: 8)
                    }
                    Text(insight.date, style: .date)
                        .font(PickleProTypography.caption)
                        .foregroundColor(PickleProColors.textTertiary)
                }

                Text(insight.title)
                    .font(PickleProTypography.headline)
                    .foregroundColor(.white)

                Text(insight.content)
                    .font(PickleProTypography.subheadline)
                    .foregroundColor(PickleProColors.textSecondary)
                    .lineSpacing(4)

                if !insight.actionItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Action Items")
                            .font(PickleProTypography.captionBold)
                            .foregroundColor(PickleProColors.accent)

                        ForEach(insight.actionItems, id: \.self) { item in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(PickleProColors.accent)
                                Text(item)
                                    .font(PickleProTypography.caption)
                                    .foregroundColor(PickleProColors.textSecondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(PickleProColors.accent.opacity(0.08))
                    .cornerRadius(10)
                }
            }
        }
    }
}

struct InsightTypeBadge: View {
    let type: AICoachInsight.InsightType

    var color: Color {
        switch type {
        case .dailyCoaching: return PickleProColors.accent
        case .skillFocus: return PickleProColors.info
        case .mentalPattern: return PickleProColors.warning
        case .drillSuggestion: return PickleProColors.teal
        case .encouragement: return PickleProColors.gold
        case .weeklyReview: return PickleProColors.success
        }
    }

    var body: some View {
        Text(type.rawValue)
            .font(PickleProTypography.captionBold)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }
}
