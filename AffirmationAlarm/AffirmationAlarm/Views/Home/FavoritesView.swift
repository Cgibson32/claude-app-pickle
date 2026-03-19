import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Affirmation> { $0.isFavorited == true },
           sort: [SortDescriptor(\Affirmation.generatedFor, order: .reverse)])
    private var favorites: [Affirmation]

    var body: some View {
        ZStack {
            GradientBackground(style: .energy)

            if favorites.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 50))
                        .foregroundColor(AppTheme.textTertiary)

                    Text("No favorited affirmations yet")
                        .font(AppTheme.title3)
                        .foregroundColor(AppTheme.textSecondary)

                    Text("Tap the heart on any affirmation\nto save it here. Favorited affirmations\nrepeat in your alarm until removed.")
                        .font(AppTheme.subheadline)
                        .foregroundColor(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        Text("Favorited affirmations repeat in your alarm sequence until you remove them.")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.textTertiary)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ForEach(favorites) { affirmation in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textTertiary)
                                    .padding(.top, 4)

                                Text(affirmation.text)
                                    .font(AppTheme.bodyFont)
                                    .foregroundColor(AppTheme.textPrimary)

                                Spacer()

                                Button {
                                    AffirmationImageRenderer.share(text: affirmation.text)
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.textTertiary)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        affirmation.isFavorited = false
                                    }
                                    HapticService.light()
                                } label: {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(AppTheme.favorite)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppTheme.cardBackground)
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
    }
    .modelContainer(for: [Affirmation.self], inMemory: true)
}
