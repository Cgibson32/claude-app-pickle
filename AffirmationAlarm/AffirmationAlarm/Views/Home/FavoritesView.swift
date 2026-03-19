import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(filter: #Predicate<Affirmation> { $0.isFavorited }, sort: \Affirmation.generatedFor, order: .reverse) private var favorites: [Affirmation]

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
                    Text("Tap the heart on any affirmation to save it here")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(AppTheme.spacingXxl)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacingMd) {
                        ForEach(favorites) { affirmation in
                            FavoriteCard(affirmation: affirmation)
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

struct FavoriteCard: View {
    let affirmation: Affirmation
    @Environment(\.modelContext) private var modelContext

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

            Button {
                HapticService.light()
                affirmation.isFavorited = false
            } label: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color(hex: "E85D75"))
            }
            .buttonStyle(.bounce)
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
    }
}
