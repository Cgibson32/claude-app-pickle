import SwiftUI
import SwiftData

struct SpeechSettingsView: View {
    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise, withBlobs: false)

            ScrollView {
                VStack(spacing: AppTheme.spacingXxl) {
                    if let profile {
                        Toggle(isOn: Binding(
                            get: { profile.ttsEnabled },
                            set: { profile.ttsEnabled = $0 }
                        )) {
                            Text("Speak affirmations aloud")
                                .font(AppTheme.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .tint(AppTheme.sunsetOrange)
                        .padding(AppTheme.spacingLg)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))

                        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                            Text("About the voice")
                                .font(AppTheme.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Your morning sequence is spoken by a warm, nurturing voice designed to feel like a calm friend beside you. It works on every device — no setup required. If you're offline, it gracefully falls back to the built-in system voice.")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppTheme.spacingLg)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
                    }
                }
                .padding(AppTheme.spacingXl)
                .animation(AppTheme.gentle, value: profile?.ttsEnabled)
            }
        }
        .navigationTitle("Voice Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
