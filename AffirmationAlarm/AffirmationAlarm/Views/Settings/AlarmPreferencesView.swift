import SwiftUI
import SwiftData

struct AlarmPreferencesView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        ZStack {
            GradientBackground(style: .calm)

            ScrollView {
                VStack(spacing: 24) {
                    // Alarm Sound Duration
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Alarm Sound Duration")
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Text("\(Int(profile.alarmSoundDuration))s")
                                .font(AppTheme.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        Text("How long the alarm sound plays before your affirmations begin.")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.textTertiary)

                        Slider(value: $profile.alarmSoundDuration, in: 3...15, step: 1)
                            .tint(AppTheme.accent)

                        HStack {
                            Text("3s")
                                .font(AppTheme.caption2)
                                .foregroundColor(AppTheme.textTertiary)
                            Spacer()
                            Text("15s")
                                .font(AppTheme.caption2)
                                .foregroundColor(AppTheme.textTertiary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.cardBackground)
                    )

                    // Affirmation Count
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Affirmations")
                            .foregroundColor(AppTheme.textPrimary)

                        Text("How many affirmations are generated for each morning.")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.textTertiary)

                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { count in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        profile.affirmationCount = count
                                    }
                                } label: {
                                    Text("\(count)")
                                        .font(AppTheme.headline)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            Circle()
                                                .fill(profile.affirmationCount == count
                                                      ? AppTheme.chipSelected
                                                      : AppTheme.chipUnselected)
                                        )
                                        .foregroundColor(profile.affirmationCount == count ? AppTheme.chipTextSelected : AppTheme.chipTextUnselected)
                                }
                            }
                        }

                        Text("Changes apply to your next alarm. Favorited affirmations are included in this count.")
                            .font(AppTheme.caption2)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.cardBackground)
                    )
                }
                .padding()
            }
        }
        .navigationTitle("Alarm Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
