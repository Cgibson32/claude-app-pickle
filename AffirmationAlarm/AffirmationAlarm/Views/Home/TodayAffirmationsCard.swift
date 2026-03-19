import SwiftUI
import SwiftData

struct TodayAffirmationsCard: View {
    @Query(sort: \Affirmation.generatedFor, order: .reverse) private var allAffirmations: [Affirmation]

    private var todayAffirmations: [Affirmation] {
        allAffirmations.filter { AppDateFormatters.isToday($0.generatedFor) }
    }

    var body: some View {
        if !todayAffirmations.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(AppTheme.gold)
                    Text("Today's Affirmations")
                        .font(AppTheme.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                }

                ForEach(todayAffirmations) { affirmation in
                    HStack(alignment: .top, spacing: AppTheme.spacingMd) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.gold.opacity(0.4))
                            .padding(.top, 4)

                        Text(affirmation.text)
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineSpacing(2)

                        Spacer(minLength: 8)

                        VStack(spacing: AppTheme.spacingSm) {
                            Button {
                                HapticService.light()
                                affirmation.isFavorited.toggle()
                            } label: {
                                Image(systemName: affirmation.isFavorited ? "heart.fill" : "heart")
                                    .foregroundStyle(affirmation.isFavorited ? Color(hex: "E85D75") : AppTheme.textTertiary)
                                    .font(.system(size: 16))
                            }

                            Button {
                                AffirmationImageRenderer.share(text: affirmation.text)
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(AppTheme.textTertiary)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(AppTheme.spacingXl)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        }
    }
}
