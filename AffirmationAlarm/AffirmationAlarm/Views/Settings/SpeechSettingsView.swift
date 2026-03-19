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
                        // TTS toggle
                        Toggle(isOn: Binding(
                            get: { profile.ttsEnabled },
                            set: { profile.ttsEnabled = $0 }
                        )) {
                            Text("Text-to-Speech")
                                .font(AppTheme.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .tint(AppTheme.sunsetOrange)
                        .padding(AppTheme.spacingLg)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))

                        if profile.ttsEnabled {
                            // Speech rate
                            VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                                HStack {
                                    Text("Speech Rate")
                                        .font(AppTheme.headline)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                    Text(rateLabel(profile.speechRate))
                                        .font(AppTheme.caption)
                                        .foregroundStyle(AppTheme.gold)
                                }
                                Slider(value: Binding(
                                    get: { profile.speechRate },
                                    set: { profile.speechRate = $0 }
                                ), in: 0.3...0.6, step: 0.02)
                                .tint(AppTheme.sunsetOrange)
                            }
                            .padding(AppTheme.spacingLg)
                            .background(AppTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))

                            // Speech pitch
                            VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                                HStack {
                                    Text("Pitch")
                                        .font(AppTheme.headline)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                    Text(pitchLabel(profile.speechPitch))
                                        .font(AppTheme.caption)
                                        .foregroundStyle(AppTheme.gold)
                                }
                                Slider(value: Binding(
                                    get: { profile.speechPitch },
                                    set: { profile.speechPitch = $0 }
                                ), in: 0.5...1.5, step: 0.05)
                                .tint(AppTheme.sunsetOrange)
                            }
                            .padding(AppTheme.spacingLg)
                            .background(AppTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
                        }
                    }
                }
                .padding(AppTheme.spacingXl)
                .animation(AppTheme.gentle, value: profile?.ttsEnabled)
            }
        }
        .navigationTitle("Voice Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func rateLabel(_ rate: Float) -> String {
        if rate < 0.4 { return "Calm" }
        if rate < 0.5 { return "Natural" }
        return "Energetic"
    }

    private func pitchLabel(_ pitch: Float) -> String {
        if pitch < 0.8 { return "Deep" }
        if pitch < 1.1 { return "Natural" }
        return "Bright"
    }
}
