import SwiftUI
import SwiftData

/// Shown when the user taps the Today Progress card on Home. Lists every
/// affirmation from their most recent alarm sequence and lets them favorite
/// or share each one. "Most recent" = affirmations sharing the latest
/// `generatedFor` day we have on file.
struct RecentAffirmationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Affirmation.generatedFor, order: .reverse) private var allAffirmations: [Affirmation]

    private var recentAffirmations: [Affirmation] {
        guard let latest = allAffirmations.first?.generatedFor else { return [] }
        let day = Calendar.current.startOfDay(for: latest)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? latest
        return allAffirmations.filter { $0.generatedFor >= day && $0.generatedFor < nextDay }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground(style: .sunrise, withBlobs: false)

                if recentAffirmations.isEmpty {
                    VStack(spacing: AppTheme.spacingLg) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.textTertiary)
                        Text("No affirmations yet")
                            .font(AppTheme.title3)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("Your alarm will generate them for you")
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .padding(AppTheme.spacingXxl)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                            ForEach(recentAffirmations) { affirmation in
                                row(for: affirmation)
                            }
                        }
                        .padding(AppTheme.spacingXl)
                    }
                }
            }
            .navigationTitle("Your Affirmations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.gold)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func row(for affirmation: Affirmation) -> some View {
        HStack(alignment: .top, spacing: AppTheme.spacingMd) {
            Image(systemName: "quote.opening")
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.gold.opacity(0.4))
                .padding(.top, 6)

            Text(affirmation.text)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textPrimary)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: AppTheme.spacingSm) {
                Button {
                    HapticService.light()
                    affirmation.favoriteType = affirmation.isPriority ? 0 : 1
                    affirmation.isFavorited = affirmation.favoriteType != 0
                } label: {
                    Image(systemName: affirmation.isPriority ? "heart.fill" : "heart")
                        .foregroundStyle(affirmation.isPriority ? Color(hex: "E85D75") : AppTheme.textTertiary)
                        .font(.system(size: 18))
                }

                Button {
                    HapticService.light()
                    affirmation.favoriteType = affirmation.isRotation ? 0 : 2
                    affirmation.isFavorited = affirmation.favoriteType != 0
                } label: {
                    Image(systemName: affirmation.isRotation ? "checkmark.circle.fill" : "checkmark.circle")
                        .foregroundStyle(affirmation.isRotation ? AppTheme.gold : AppTheme.textTertiary)
                        .font(.system(size: 18))
                }

                Button {
                    AffirmationImageRenderer.share(text: affirmation.text)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(AppTheme.textTertiary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
    }
}
