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
                        // Sound duration
                        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                            HStack {
                                Text("Alarm Sound Duration")
                                    .font(AppTheme.headline)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                Text("\(Int(profile.alarmSoundDuration))s")
                                    .font(AppTheme.subheadline)
                                    .foregroundStyle(AppTheme.gold)
                            }
                            Slider(value: Binding(
                                get: { profile.alarmSoundDuration },
                                set: { profile.alarmSoundDuration = $0 }
                            ), in: 3...15, step: 1)
                            .tint(AppTheme.sunsetOrange)
                        }
                        .padding(AppTheme.spacingLg)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))

                        // Affirmation count
                        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                            Text("Daily Affirmations")
                                .font(AppTheme.headline)
                                .foregroundStyle(AppTheme.textPrimary)

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
                    }
                }
                .padding(AppTheme.spacingXl)
            }
        }
        .navigationTitle("Alarm Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}
