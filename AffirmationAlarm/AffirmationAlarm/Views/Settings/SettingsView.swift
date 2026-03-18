import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var apiKey = ""
    @State private var showAPIKeyField = false
    @State private var apiKeySaved = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            GradientBackground(style: .calm)

            ScrollView {
                VStack(spacing: 20) {
                    // Profile Section
                    settingsSection(title: "Profile") {
                        if let profile {
                            NavigationLink {
                                ProfileEditView(profile: profile)
                            } label: {
                                settingsRow(icon: "person.fill", title: "Name & Goals", detail: profile.name)
                            }
                        }
                    }

                    // Alarm Section
                    settingsSection(title: "Alarm") {
                        if let profile {
                            NavigationLink {
                                AlarmPreferencesView(profile: profile)
                            } label: {
                                settingsRow(
                                    icon: "alarm.fill",
                                    title: "Alarm Preferences",
                                    detail: "\(profile.affirmationCount) affirmations"
                                )
                            }
                        }
                    }

                    // Voice Section
                    settingsSection(title: "Voice") {
                        if let profile {
                            NavigationLink {
                                SpeechSettingsView(profile: profile)
                            } label: {
                                settingsRow(
                                    icon: "speaker.wave.2.fill",
                                    title: "Voice Settings",
                                    detail: profile.ttsEnabled ? "On" : "Off"
                                )
                            }
                        }
                    }

                    // API Key Section
                    settingsSection(title: "AI Configuration") {
                        VStack(spacing: 12) {
                            Button {
                                withAnimation { showAPIKeyField.toggle() }
                            } label: {
                                settingsRow(
                                    icon: "key.fill",
                                    title: "API Key",
                                    detail: APIKeyConfiguration.hasAPIKey ? "Configured" : "Not Set"
                                )
                            }

                            if showAPIKeyField {
                                VStack(spacing: 8) {
                                    SecureField("Enter Anthropic API Key", text: $apiKey)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(AppTheme.inputBackground)
                                        )
                                        .foregroundColor(AppTheme.textPrimary)
                                        .tint(AppTheme.cream)

                                    Button {
                                        saveAPIKey()
                                    } label: {
                                        Text(apiKeySaved ? "Saved!" : "Save Key")
                                            .font(AppTheme.subheadline)
                                            .foregroundColor(AppTheme.accentText)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                Capsule().fill(apiKey.isEmpty ? AppTheme.buttonDisabled : AppTheme.buttonBackground)
                                            )
                                    }
                                    .disabled(apiKey.isEmpty)

                                    Text("Your API key is stored securely in the iOS Keychain.")
                                        .font(AppTheme.caption2)
                                        .foregroundColor(AppTheme.textTertiary)
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }

                    // About Section
                    settingsSection(title: "About") {
                        settingsRow(icon: "info.circle.fill", title: "Version", detail: "1.0.0")
                        settingsRow(icon: "sunrise.fill", title: "Affirmation Alarm", detail: "")
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Components

    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.caption)
                .textCase(.uppercase)
                .foregroundColor(AppTheme.textSecondary)

            VStack(spacing: 1) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardBackground)
            )
        }
    }

    private func settingsRow(icon: String, title: String, detail: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.accent)
                .frame(width: 28)

            Text(title)
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            if !detail.isEmpty {
                Text(detail)
                    .font(AppTheme.subheadline)
                    .foregroundColor(AppTheme.textTertiary)
            }

            Image(systemName: "chevron.right")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding()
    }

    private func saveAPIKey() {
        if APIKeyConfiguration.saveAPIKey(apiKey) {
            apiKeySaved = true
            apiKey = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                apiKeySaved = false
                showAPIKeyField = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [UserProfile.self], inMemory: true)
}
