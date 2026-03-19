import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise, withBlobs: false)

            ScrollView {
                VStack(spacing: AppTheme.spacingMd) {
                    // Profile
                    NavigationLink {
                        ProfileEditView()
                    } label: {
                        SettingsRow(icon: "person.fill", title: "Profile", color: AppTheme.sunsetOrange)
                    }

                    // Alarm preferences
                    NavigationLink {
                        AlarmPreferencesView()
                    } label: {
                        SettingsRow(icon: "alarm.fill", title: "Alarm Preferences", color: AppTheme.gold)
                    }

                    // Voice settings
                    NavigationLink {
                        SpeechSettingsView()
                    } label: {
                        SettingsRow(icon: "speaker.wave.2.fill", title: "Voice Settings", color: AppTheme.warmAmber)
                    }

                    // Evening reflection
                    NavigationLink {
                        EveningReflectionSettingsView()
                    } label: {
                        SettingsRow(icon: "moon.stars.fill", title: "Evening Reflection", color: AppTheme.deepPlum)
                    }

                    // About
                    VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                        Text("About")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                            .padding(.top, AppTheme.spacingLg)

                        HStack {
                            Text("Affirmation Alarm")
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Text("v1.0.0")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                        .padding(AppTheme.spacingLg)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    }
                }
                .padding(AppTheme.spacingXl)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.spacingMd) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(title)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }
}
