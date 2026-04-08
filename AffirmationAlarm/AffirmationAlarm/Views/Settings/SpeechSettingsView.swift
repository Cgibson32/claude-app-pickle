import SwiftUI
import SwiftData

struct SpeechSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var alarms: [Alarm]
    private var profile: UserProfile? { profiles.first }

    /// Which voice (if any) is currently speaking a sample. Used to disable
    /// other preview buttons while one is playing and show a speaker icon
    /// next to the active one.
    @State private var previewingVoice: OpenAITTSService.Voice?

    /// Held as `@State` rather than instantiating fresh each tap, so the
    /// underlying OpenAI cache persists across previews — a second tap on
    /// the same voice plays instantly.
    @State private var previewSpeech = SpeechService()

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

                        voiceSection(profile: profile)

                        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                            Text("About the voice")
                                .font(AppTheme.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Your morning sequence is spoken by a warm, nurturing voice designed to feel like a calm friend beside you. Pick the one that sounds most like the voice you want to wake up to. If you're offline, it gracefully falls back to the built-in system voice.")
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
                .animation(AppTheme.gentle, value: profile?.ttsVoice)
            }
        }
        .navigationTitle("Voice Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            previewSpeech.stop()
        }
    }

    @ViewBuilder
    private func voiceSection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            Text("Voice")
                .font(AppTheme.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                ForEach(OpenAITTSService.Voice.allCases, id: \.self) { voice in
                    voiceRow(voice: voice, profile: profile)
                    if voice != OpenAITTSService.Voice.allCases.last {
                        Divider().background(AppTheme.strokeLight)
                    }
                }
            }
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        }
    }

    @ViewBuilder
    private func voiceRow(voice: OpenAITTSService.Voice, profile: UserProfile) -> some View {
        let isSelected = profile.ttsVoice == voice.rawValue
        let isPreviewing = previewingVoice == voice

        HStack(spacing: AppTheme.spacingMd) {
            VStack(alignment: .leading, spacing: 2) {
                Text(voice.displayName)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(voice.tagline)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer()

            Button {
                HapticService.selection()
                preview(voice: voice, profile: profile)
            } label: {
                Image(systemName: isPreviewing ? "speaker.wave.2.fill" : "play.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(isPreviewing ? AppTheme.sunsetOrange : AppTheme.gold)
            }
            .buttonStyle(.plain)
            .disabled(previewingVoice != nil && !isPreviewing)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.gold)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            HapticService.selection()
            select(voice: voice, profile: profile)
        }
        .padding(.horizontal, AppTheme.spacingLg)
        .padding(.vertical, AppTheme.spacingMd)
    }

    // MARK: - Actions

    /// Persist the new voice choice, invalidate every pre-rendered alarm
    /// audio file (yesterday's Nova recording isn't what they just asked
    /// for), and kick off a fresh render + reschedule for every enabled
    /// alarm so tomorrow morning uses the new voice.
    private func select(voice: OpenAITTSService.Voice, profile: UserProfile) {
        profile.ttsVoice = voice.rawValue
        try? modelContext.save()

        MorningAudioRenderer.shared.invalidateAll()

        let enabledAlarms = alarms.filter { $0.isEnabled }
        let context = modelContext
        Task { @MainActor in
            await MorningAudioRenderer.shared.refreshAll(
                alarms: enabledAlarms,
                profile: profile,
                modelContext: context
            )
            for alarm in enabledAlarms {
                AlarmKitScheduler.shared.scheduleAlarm(alarm)
            }
        }
    }

    /// Play a short sample of the given voice using the user's actual name
    /// so they can hear what they'll wake up to. Clears the existing
    /// preview before starting a new one.
    private func preview(voice: OpenAITTSService.Voice, profile: UserProfile) {
        previewSpeech.stop()

        let trimmedName = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let sample = trimmedName.isEmpty
            ? "Good morning. Today is yours — rise gently and begin."
            : "Good morning, \(trimmedName). Today is yours — rise gently and begin."

        previewingVoice = voice
        previewSpeech.voice = voice

        Task { @MainActor in
            await previewSpeech.speakAndWait(text: sample)
            if previewingVoice == voice {
                previewingVoice = nil
            }
        }
    }
}
