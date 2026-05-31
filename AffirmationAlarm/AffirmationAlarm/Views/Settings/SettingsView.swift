import SwiftUI
import SwiftData

/// Settings hub organized into labelled sections so related toggles sit
/// together. "Personal" merges the old Profile + Alarm Preferences pages
/// — name, goals, focus areas, affirmation count, and length all answer
/// "what does my morning sound like?" so one screen saves the user a tap.
struct SettingsView: View {
    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise, withBlobs: false)

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacingXl) {
                    section("Personal") {
                        NavigationLink {
                            PersonalSettingsView()
                        } label: {
                            SettingsRow(icon: "person.fill", title: "Profile & Affirmations", color: AppTheme.sunsetOrange)
                        }
                    }

                    section("Voice & Audio") {
                        NavigationLink {
                            SpeechSettingsView()
                        } label: {
                            SettingsRow(icon: "speaker.wave.2.fill", title: "Voice", color: AppTheme.warmAmber)
                        }

                        if let profile {
                            AlarmVolumeRow(profile: profile)
                        }
                    }

                    section("Advanced") {
                        NavigationLink {
                            DiagnosticsView()
                        } label: {
                            SettingsRow(icon: "stethoscope", title: "Diagnostics", color: AppTheme.textSecondary)
                        }
                    }

                    aboutCard
                }
                .padding(AppTheme.spacingXl)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            Text(title.uppercased())
                .font(AppTheme.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textTertiary)
                .tracking(0.6)
                .padding(.horizontal, AppTheme.spacingSm)
            content()
        }
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            Text("ABOUT")
                .font(AppTheme.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textTertiary)
                .tracking(0.6)
                .padding(.horizontal, AppTheme.spacingSm)

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
}

private struct AlarmVolumeRow: View {
    @Bindable var profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            HStack {
                Image(systemName: "alarm.waves.left.and.right")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.warmAmber)
                Text("Alarm Volume")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(Int(profile.alarmVolume * 100))%")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textTertiary)
                    .monospacedDigit()
            }

            HStack(spacing: AppTheme.spacingSm) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textTertiary)
                Slider(value: $profile.alarmVolume, in: 0.3...1.0, step: 0.05)
                    .tint(AppTheme.warmAmber)
                    .onChange(of: profile.alarmVolume) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: VolumeBooster.volumeKey)
                    }
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .onAppear {
            UserDefaults.standard.set(profile.alarmVolume, forKey: VolumeBooster.volumeKey)
        }
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
