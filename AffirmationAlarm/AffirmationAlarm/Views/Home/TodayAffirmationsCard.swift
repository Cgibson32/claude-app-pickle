import SwiftUI
import SwiftData

/// Inline home-screen card showing the affirmations from the most recent
/// morning alarm. The user can read, favorite (heart = priority, check =
/// rotation), and share individual affirmations here. This is the only
/// way they interact with their affirmations in-app — the spoken ritual
/// itself only happens during the alarm ring.
///
/// When no affirmations have been generated yet (first install before the
/// first alarm fire, or the renderer is still catching up after a voice
/// change) the card shows a gentle placeholder instead of collapsing
/// entirely, so the home-screen layout stays balanced.
struct TodayAffirmationsCard: View {
    @Query(
        filter: #Predicate<Affirmation> { $0.isCustom == false },
        sort: \Affirmation.generatedFor,
        order: .reverse
    ) private var allAffirmations: [Affirmation]

    /// Affirmations from the most recent generation, but only if
    /// generated within the last 24 hours. Older rows are stale
    /// leftovers and should show the empty/generating state instead.
    private var recentAffirmations: [Affirmation] {
        guard let newest = allAffirmations.first else { return [] }
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        guard newest.generatedFor > cutoff else { return [] }
        return allAffirmations.filter {
            Calendar.current.isDate($0.generatedFor, inSameDayAs: newest.generatedFor)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppTheme.gold)
                Text("Today's Affirmations")
                    .font(AppTheme.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }

            if recentAffirmations.isEmpty {
                emptyState
            } else {
                ForEach(recentAffirmations) { affirmation in
                    row(for: affirmation)
                }
            }
        }
        .padding(AppTheme.spacingXl)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
    }

    private var emptyState: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingMd) {
            Image(systemName: "sun.horizon")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.gold.opacity(0.7))
                .padding(.top, 2)

            Text("Your next alarm will bring your personalized affirmations here to read and favorite.")
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, AppTheme.spacingSm)
    }

    @ViewBuilder
    private func row(for affirmation: Affirmation) -> some View {
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
                // Priority (heart) button
                Button {
                    HapticService.light()
                    affirmation.favoriteType = affirmation.isPriority ? 0 : 1
                    affirmation.isFavorited = affirmation.favoriteType != 0
                } label: {
                    Image(systemName: affirmation.isPriority ? "heart.fill" : "heart")
                        .foregroundStyle(affirmation.isPriority ? AppTheme.gold : AppTheme.textTertiary)
                        .font(.system(size: 16))
                }
                .accessibilityLabel(affirmation.isPriority ? "Remove from priority favorites" : "Add to priority favorites")

                // Rotation (checkmark) button
                Button {
                    HapticService.light()
                    affirmation.favoriteType = affirmation.isRotation ? 0 : 2
                    affirmation.isFavorited = affirmation.favoriteType != 0
                } label: {
                    Image(systemName: affirmation.isRotation ? "checkmark.circle.fill" : "checkmark.circle")
                        .foregroundStyle(affirmation.isRotation ? AppTheme.gold : AppTheme.textTertiary)
                        .font(.system(size: 16))
                }
                .accessibilityLabel(affirmation.isRotation ? "Remove from rotation" : "Add to rotation")

                Button {
                    AffirmationImageRenderer.share(text: affirmation.text)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(AppTheme.textTertiary)
                        .font(.system(size: 14))
                }
                .accessibilityLabel("Share affirmation")
            }
        }
        .padding(.vertical, 4)
    }
}
