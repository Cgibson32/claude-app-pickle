import SwiftUI
import SwiftData

struct AlarmPreferencesView: View {
    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise, withBlobs: false)

            ScrollView {
                VStack(spacing: AppTheme.spacingXxl) {
                    if let profile {
                        // Affirmation count
                        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                            Text("Daily Affirmations")
                                .font(AppTheme.headline)
                                .foregroundStyle(AppTheme.textPrimary)

                            Text("How many affirmations you hear each morning.")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textSecondary)

                            HStack(spacing: AppTheme.spacingMd) {
                                ForEach(1...5, id: \.self) { count in
                                    Button("\(count)") {
                                        HapticService.selection()
                                        profile.affirmationCount = count
                                    }
                                    .font(AppTheme.headline)
                                    .foregroundStyle(count == profile.affirmationCount ? AppTheme.charcoalBlue : AppTheme.textSecondary)
                                    .frame(width: 44, height: 44)
                                    .background(count == profile.affirmationCount ? AppTheme.gold : AppTheme.cardBackground)
                                    .clipShape(Circle())
                                    .buttonStyle(.bounce)
                                }
                            }
                        }
                        .padding(AppTheme.spacingLg)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))

                        // Affirmation length / word budget
                        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                            Text("Length")
                                .font(AppTheme.headline)
                                .foregroundStyle(AppTheme.textPrimary)

                            Text(profile.budget.caption)
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                                .animation(.easeInOut(duration: 0.15), value: profile.budget)

                            HStack(spacing: AppTheme.spacingMd) {
                                ForEach(AffirmationBudget.allCases, id: \.self) { option in
                                    Button(option.label) {
                                        HapticService.selection()
                                        profile.budget = option
                                        MorningAudioRenderer.shared.invalidateAll()
                                    }
                                    .font(AppTheme.headline)
                                    .foregroundStyle(option == profile.budget ? AppTheme.charcoalBlue : AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(option == profile.budget ? AppTheme.gold : AppTheme.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                                    .buttonStyle(.bounce)
                                }
                            }
                        }
                        .padding(AppTheme.spacingLg)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
                    }
                }
                .padding(AppTheme.spacingXl)
            }
        }
        .navigationTitle("Alarm Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}
