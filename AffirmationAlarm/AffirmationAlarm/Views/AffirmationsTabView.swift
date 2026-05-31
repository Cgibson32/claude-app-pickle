import SwiftUI
import SwiftData

/// Dedicated tab for reviewing affirmations — today's generated set and
/// saved favorites. Keeps the Home tab clean (glance only) while giving
/// users a place to revisit, favorite, and share their affirmations.
struct AffirmationsTabView: View {
    @State private var selectedSection: Section = .today

    enum Section: String, CaseIterable {
        case today = "Today"
        case favorites = "Favorites"
    }

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise, withBlobs: false)

            VStack(spacing: 0) {
                Picker("Section", selection: $selectedSection) {
                    ForEach(Section.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.spacingXl)
                .padding(.top, AppTheme.spacingMd)

                switch selectedSection {
                case .today:
                    TodaySection()
                case .favorites:
                    FavoritesSection()
                }
            }
        }
        .navigationTitle("Affirmations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Today

private struct TodaySection: View {
    @Query(
        filter: #Predicate<Affirmation> { $0.isPoolGenerated == false },
        sort: \Affirmation.generatedFor,
        order: .reverse
    ) private var allAffirmations: [Affirmation]
    @Query private var profiles: [UserProfile]
    @Query(sort: \Alarm.hour) private var alarms: [Alarm]
    @Environment(\.modelContext) private var modelContext

    private var recentAffirmations: [Affirmation] {
        guard let newest = allAffirmations.first else { return [] }
        let cutoff = Date().addingTimeInterval(-12 * 60 * 60)
        guard newest.generatedFor > cutoff else { return [] }
        let sameBatch = allAffirmations.filter {
            abs($0.generatedFor.timeIntervalSince(newest.generatedFor)) < 60
        }
        if sameBatch.allSatisfy({ BundledAffirmationPool.affirmations.contains($0.text) }) {
            return []
        }
        return sameBatch
    }

    var body: some View {
        if recentAffirmations.isEmpty {
            VStack(spacing: AppTheme.spacingLg) {
                Spacer()
                Image(systemName: "sun.horizon")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.textTertiary)
                Text("No affirmations yet")
                    .font(AppTheme.title3)
                    .foregroundStyle(AppTheme.textSecondary)
                Text("Your next alarm will generate personalized affirmations here.")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(AppTheme.spacingXxl)
        } else {
            List {
                ForEach(recentAffirmations) { affirmation in
                    AffirmationRow(affirmation: affirmation)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(
                            top: AppTheme.spacingSm,
                            leading: AppTheme.spacingXl,
                            bottom: AppTheme.spacingSm,
                            trailing: AppTheme.spacingXl
                        ))
                }
                .onDelete { offsets in
                    deleteAndRegenerate(at: offsets)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func deleteAndRegenerate(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(recentAffirmations[index])
        }
        HapticService.light()

        guard let profile = profiles.first else { return }
        // Manual "regenerate affirmations" — invalidate pool and refill.
        AffirmationPool.shared.invalidateAll()
        let context = modelContext
        Task { @MainActor in
            await AffirmationPool.shared.refresh(profile: profile, modelContext: context)
        }
    }
}

// MARK: - Favorites

private struct FavoritesSection: View {
    @Query(filter: #Predicate<Affirmation> { $0.favoriteType > 0 }, sort: \Affirmation.generatedFor, order: .reverse) private var favorites: [Affirmation]

    private var priorityFavorites: [Affirmation] {
        favorites.filter { $0.isPriority }
    }

    private var rotationFavorites: [Affirmation] {
        favorites.filter { $0.isRotation }
    }

    var body: some View {
        if favorites.isEmpty {
            VStack(spacing: AppTheme.spacingLg) {
                Spacer()
                Image(systemName: "heart.slash")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.textTertiary)
                Text("No favorites yet")
                    .font(AppTheme.title3)
                    .foregroundStyle(AppTheme.textSecondary)
                Text("Tap the heart on any affirmation to save it here.")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(AppTheme.spacingXxl)
        } else {
            ScrollView {
                VStack(spacing: AppTheme.spacingXl) {
                    if !priorityFavorites.isEmpty {
                        FavoriteGroup(
                            title: "Always Play",
                            icon: "heart.fill",
                            iconColor: AppTheme.gold,
                            affirmations: priorityFavorites
                        )
                    }
                    if !rotationFavorites.isEmpty {
                        FavoriteGroup(
                            title: "Rotation",
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
}

private struct FavoriteGroup: View {
    let title: String
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

            ForEach(affirmations) { affirmation in
                AffirmationRow(affirmation: affirmation)
            }
        }
    }
}

// MARK: - Shared row

private struct AffirmationRow: View {
    let affirmation: Affirmation

    var body: some View {
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
                    affirmation.favoriteType = affirmation.isPriority ? 0 : 1
                    affirmation.isFavorited = affirmation.favoriteType != 0
                } label: {
                    Image(systemName: affirmation.isPriority ? "heart.fill" : "heart")
                        .foregroundStyle(affirmation.isPriority ? AppTheme.gold : AppTheme.textTertiary)
                        .font(.system(size: 16))
                }
                .accessibilityLabel(affirmation.isPriority ? "Remove from Always Play" : "Add to Always Play")

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
        .padding(AppTheme.spacingLg)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
    }
}
