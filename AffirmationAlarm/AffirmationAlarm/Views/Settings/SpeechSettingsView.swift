import SwiftUI
import SwiftData

struct SpeechSettingsView: View {
    @Bindable var profile: UserProfile
    @State private var isPreviewing = false

    var body: some View {
        ZStack {
            GradientBackground(style: .calm)

            ScrollView {
                VStack(spacing: 24) {
                    // TTS Toggle
                    Toggle(isOn: $profile.ttsEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Text-to-Speech")
                                .foregroundColor(.white)
                            Text("Speak affirmations aloud during alarm")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .tint(.orange)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.1))
                    )

                    if profile.ttsEnabled {
                        // Speech Rate
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Speech Rate")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(rateLabel)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Slider(value: $profile.speechRate, in: 0.3...0.6, step: 0.02)
                                .tint(.orange)

                            HStack {
                                Text("Slower")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.4))
                                Spacer()
                                Text("Faster")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.1))
                        )

                        // Speech Pitch
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Voice Pitch")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(pitchLabel)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Slider(value: $profile.speechPitch, in: 0.5...1.5, step: 0.05)
                                .tint(.orange)

                            HStack {
                                Text("Lower")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.4))
                                Spacer()
                                Text("Higher")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.1))
                        )

                        // Preview button
                        Button {
                            previewVoice()
                        } label: {
                            HStack {
                                Image(systemName: isPreviewing ? "speaker.wave.3.fill" : "play.fill")
                                Text(isPreviewing ? "Speaking..." : "Preview Voice")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white.opacity(0.2))
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
