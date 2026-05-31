import SwiftUI
import SwiftData

struct SpeechSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var alarms: [Alarm]
    private var profile: UserProfile? { profiles.first }

    /// Which voice (if any) is currently being previewed. Set to the voice
    /// as soon as the user taps its play button and cleared when the audio
    /// finishes. The preview button shows a speaker-wave icon while active,
    /// and all other rows' play buttons are disabled to prevent overlapping
    /// playback.
    @State private var previewingVoice: ElevenLabsTTSService.Voice?

    /// Held as `@State` rather than instantiating fresh each tap, so the
    /// underlying OpenAI cache persists across previews — a second tap on
    /// the same voice plays instantly.
    @State private var previewSpeech = VoicePreviewService()

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise, withBlobs: false)

            ScrollView {
                VStack(spacing: AppTheme.spacingXxl) {
                    if let profile {
                        voiceSection(profile: profile)
                    }

                    if let error = previewSpeech.lastError {
                        Text(error)
                            .font(AppTheme.caption)
                            .foregroundStyle(.red.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppTheme.spacingMd)
                    }
                }
                .padding(AppTheme.spacingXl)
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
                ForEach(ElevenLabsTTSService.Voice.allCases, id: \.self) { voice in
                    voiceRow(voice: voice, profile: profile)
                    if voice != ElevenLabsTTSService.Voice.allCases.last {
                        Divider().background(AppTheme.strokeLight)
                    }
                }
            }
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        }
    }

    @ViewBuilder
    private func voiceRow(voice: ElevenLabsTTSService.Voice, profile: UserProfile) -> some View {
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
            .accessibilityLabel(isPreviewing ? "Stop \(voice.displayName) preview" : "Play \(voice.displayName) preview")

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.gold)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            HapticService.selection()
            select(voice: voice, profile: profile)
        }
        .padding(.horizontal, AppTheme.spacingLg)
        .padding(.vertical, AppTheme.spacingMd)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(voice.displayName), \(voice.tagline)\(isSelected ? ", selected voice" : "")")
        .accessibilityHint("Double tap to select this voice")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Actions

    /// Persist the new voice choice, invalidate every pre-rendered alarm
    /// audio file (yesterday's Nova recording isn't what they just asked
    /// for), and kick off a fresh render + reschedule for every enabled
    /// alarm so tomorrow morning uses the new voice.
    private func select(voice: ElevenLabsTTSService.Voice, profile: UserProfile) {
        profile.ttsVoice = voice.rawValue
        try? modelContext.save()

        // Voice change invalidates the entire affirmation pool — all
        // 20 pre-rendered files use the old voice. The pool's signature
        // hash includes ttsVoice, so refresh() will detect the mismatch
        // and rebuild from scratch.
        AffirmationPool.shared.invalidateAll()

        let enabledAlarms = alarms.filter { $0.isEnabled }
        let context = modelContext
        Task { @MainActor in
            await AffirmationPool.shared.refresh(profile: profile, modelContext: context)
            for alarm in enabledAlarms {
                AlarmKitScheduler.shared.scheduleAlarm(alarm)
            }
        }
    }

    /// Play a short sample of the given voice using the user's actual name
    /// so they can hear what they'll wake up to. Clears any in-flight
    /// preview before starting a new one. First tap of any voice has a
    /// ~1s OpenAI round-trip; subsequent taps hit the in-memory cache in
    /// the TTS service and play instantly.
    private func preview(voice: ElevenLabsTTSService.Voice, profile: UserProfile) {
        previewSpeech.stop()

        let trimmedName = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let sample = trimmedName.isEmpty
            ? "Good morning. Today is yours — rise gently and begin."
            : "Good morning, \(trimmedName). Today is yours — rise gently and begin."

        previewingVoice = voice
        previewSpeech.voice = voice

        Task { @MainActor in
            await previewSpeech.preview(text: sample)
            if previewingVoice == voice {
                previewingVoice = nil
            }
        }
    }
}
