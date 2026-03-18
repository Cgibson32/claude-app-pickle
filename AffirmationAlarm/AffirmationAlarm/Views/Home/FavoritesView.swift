import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Affirmation> { $0.isFavorited == true },
           sort: [SortDescriptor(\Affirmation.generatedFor, order: .reverse)])
    private var favorites: [Affirmation]

    var body: some View {
        ZStack {
            GradientBackground(style: .warmEvening)

            if favorites.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.4))

                    Text("No favorited affirmations yet")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.7))

                    Text("Tap the heart on any affirmation\nto save it here. Favorited affirmations\nrepeat in your alarm until removed.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        Text("Favorited affirmations repeat in your alarm sequence until you remove them.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ForEach(favorites) { affirmation in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "quote.opening")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.4))
                                    .padding(.top, 4)

                                Text(affirmation.text)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))

                                Spacer()

                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        affirmation.isFavorited = false
                                    }
                                } label: {
                                    Image(systemName: "heart.fill")
                                        .font(.title3)
                                        .foregroundColor(.pink)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.white.opacity(0.1))
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
