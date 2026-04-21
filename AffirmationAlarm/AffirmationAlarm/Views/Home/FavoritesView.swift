import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(filter: #Predicate<Affirmation> { $0.favoriteType > 0 }, sort: \Affirmation.generatedFor, order: .reverse) private var favorites: [Affirmation]

    private var priorityFavorites: [Affirmation] {
        favorites.filter { $0.isPriority }
    }

    private var rotationFavorites: [Affirmation] {
        favorites.filter { $0.isRotation }
    }

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise, withBlobs: false)

            if favorites.isEmpty {
                VStack(spacing: AppTheme.spacingLg) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("No favorites yet")
                        .font(AppTheme.title3)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("Tap the heart or checkmark on any affirmation to save it here")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(AppTheme.spacingXxl)
            } else {
                ScrollView {
                    VStack(spacing: AppTheme.spacingXl) {
                        // Priority section
                        if !priorityFavorites.isEmpty {
                            FavoritesSection(
                                title: "Priority",
                                subtitle: "Repeated every morning",
                                icon: "heart.fill",
                                iconColor: Color(hex: "E85D75"),
                                affirmations: priorityFavorites
                            )
                        }

                        // Rotation section
                        if !rotationFavorites.isEmpty {
                            FavoritesSection(
                                title: "Rotation",
                                subtitle: "Rotated in with daily affirmations",
                                icon: "checkmark.circle.fill",
                                iconColor: AppTheme.gold,
                                affirmations: rotationFavorites
                            )
                        }
                    }
                    .padding(AppTheme.spacingXl)
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Section

private struct FavoritesSection: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let affirmations: [Affirmation]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack(spacing: AppTheme.spacingSm) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.system(size: 14))
                Text(title)
                    .font(AppTheme.headline)
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Text(subtitle)
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textTertiary)

            ForEach(affirmations) { affirmation in
                FavoriteCard(affirmation: affirmation)
            }
        }
    }
}

// MARK: - Card

struct FavoriteCard: View {
    let affirmation: Affirmation

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingMd) {
            Image(systemName: "quote.opening")
                .foregroundStyle(AppTheme.gold.opacity(0.5))
                .font(.system(size: 14))

            Text(affirmation.text)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textPrimary)
                .lineSpacing(4)

            Spacer()

            VStack(spacing: AppTheme.spacingSm) {
                // Priority toggle
                Button {
                    HapticService.light()
                    affirmation.favoriteType = affirmation.isPriority ? 0 : 1
                    affirmation.isFavorited = affirmation.favoriteType != 0
                } label: {
                    Image(systemName: affirmation.isPriority ? "heart.fill" : "heart")
                        .foregroundStyle(affirmation.isPriority ? Color(hex: "E85D75") : AppTheme.textTertiary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.bounce)
                .accessibilityLabel(affirmation.isPriority ? "Remove from priority favorites" : "Add to priority favorites")

                // Rotation toggle
                Button {
                    HapticService.light()
                    affirmation.favoriteType = affirmation.isRotation ? 0 : 2
                    affirmation.isFavorited = affirmation.favoriteType != 0
                } label: {
                    Image(systemName: affirmation.isRotation ? "checkmark.circle.fill" : "checkmark.circle")
                        .foregroundStyle(affirmation.isRotation ? AppTheme.gold : AppTheme.textTertiary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.bounce)
                .accessibilityLabel(affirmation.isRotation ? "Remove from rotation" : "Add to rotation")

                Button {
                    AffirmationImageRenderer.share(text: affirmation.text)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(AppTheme.textTertiary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.bounce)
                .accessibilityLabel("Share affirmation")
            }
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
    }
}
