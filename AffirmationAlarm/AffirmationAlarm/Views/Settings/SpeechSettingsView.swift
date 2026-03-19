import SwiftUI
import SwiftData

struct SpeechSettingsView: View {
    @Bindable var profile: UserProfile
    @State private var isPreviewing = false

    var body: some View {
        ZStack {
            GradientBackground(style: .glow)

            ScrollView {
                VStack(spacing: 24) {
                    // TTS Toggle
                    Toggle(isOn: $profile.ttsEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Text-to-Speech")
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Speak affirmations aloud during alarm")
                                .font(AppTheme.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .tint(AppTheme.accent)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.cardBackground)
                    )

                    if profile.ttsEnabled {
                        // Speech Rate
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Speech Rate")
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                Text(rateLabel)
                                    .font(AppTheme.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            Slider(value: $profile.speechRate, in: 0.3...0.6, step: 0.02)
                                .tint(AppTheme.accent)

                            HStack {
                                Text("Slower")
                                    .font(AppTheme.caption2)
                                    .foregroundColor(AppTheme.textTertiary)
                                Spacer()
                                Text("Faster")
                                    .font(AppTheme.caption2)
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.cardBackground)
                        )

                        // Speech Pitch
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Voice Pitch")
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                Text(pitchLabel)
                                    .font(AppTheme.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            Slider(value: $profile.speechPitch, in: 0.5...1.5, step: 0.05)
                                .tint(AppTheme.accent)

                            HStack {
                                Text("Lower")
                                    .font(AppTheme.caption2)
                                    .foregroundColor(AppTheme.textTertiary)
                                Spacer()
                                Text("Higher")
                                    .font(AppTheme.caption2)
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.cardBackground)
                        )

                        // Preview button
                        Button {
                            previewVoice()
                        } label: {
                            HStack {
                                Image(systemName: isPreviewing ? "speaker.wave.3.fill" : "play.fill")
                                Text(isPreviewing ? "Speaking..." : "Preview Voice")
                            }
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.chipUnselected)
                            )
                        }
                        .disabled(isPreviewing)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Voice Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var rateLabel: String {
        if profile.speechRate < 0.38 { return "Calm" }
        if profile.speechRate < 0.48 { return "Natural" }
        return "Energetic"
    }

    private var pitchLabel: String {
        if profile.speechPitch < 0.7 { return "Deep" }
        if profile.speechPitch < 1.0 { return "Natural" }
        return "Bright"
    }

    private func previewVoice() {
        isPreviewing = true
        let speechService = SpeechService.shared
        speechService.configure(rate: profile.speechRate, pitch: profile.speechPitch)
        speechService.speakSequence(
            items: [
                SpeechItem(text: "Good morning, \(profile.name). You are capable of amazing things.", postDelay: 0)
            ],
            onComplete: {
                DispatchQueue.main.async {
                    isPreviewing = false
                }
            }
        )
    }
}
