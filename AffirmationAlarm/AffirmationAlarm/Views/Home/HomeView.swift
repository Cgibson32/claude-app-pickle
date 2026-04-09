import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \Alarm.hour) private var alarms: [Alarm]
    @State private var customAffirmationText = ""

    /// Set to `true` by `OnboardingViewModel.completeOnboarding` while the
    /// first morning's audio is being rendered (~5-10s for Claude + TTS
    /// round-trips) and cleared when rendering finishes. HomeView shows a
    /// friendly "Preparing your first morning ritual..." banner while true
    /// so the empty-state home screen doesn't feel broken.
    @AppStorage("isPreparingFirstMorning") private var isPreparingFirstMorning = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground(style: .sunrise)

                ScrollView {
                    VStack(spacing: AppTheme.spacingXl) {
                        // Greeting
                        greetingSection

                        if isPreparingFirstMorning {
                            preparingBanner
                        }

                        // Next alarm card
                        NextAlarmCard(alarms: alarms)

                        // Custom affirmation input
                        customAffirmationInput

                        // Today's affirmations — the ones spoken by the
                        // most recent alarm, shown inline as text with
                        // heart/checkmark favorite buttons. This is the
                        // only way users revisit affirmations in-app; the
                        // spoken ritual only happens during the alarm ring.
                        TodayAffirmationsCard()

                        // Quick actions
                        quickActionsGrid

                        Spacer().frame(height: AppTheme.spacingXl)
                    }
                    .padding(.horizontal, AppTheme.spacingXl)
                    .padding(.top, AppTheme.spacingLg)
                    .animation(AppTheme.gentle, value: isPreparingFirstMorning)
                }

            }
            .preferredColorScheme(.dark)
        }
    }

    /// Dismissible-by-completion banner shown only during the 5-10s window
    /// after the user finishes onboarding and the first alarm audio is
    /// being generated. Auto-dismisses when
    /// `OnboardingViewModel.completeOnboarding`'s render Task clears the
    /// `isPreparingFirstMorning` flag in UserDefaults.
    private var preparingBanner: some View {
        HStack(spacing: AppTheme.spacingMd) {
            ProgressView()
                .controlSize(.small)
                .tint(AppTheme.gold)

            VStack(alignment: .leading, spacing: 2) {
                Text("Preparing your first morning")
                    .font(AppTheme.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Crafting your personalized affirmations in your chosen voice.")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.gold.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .transition(.opacity.combined(with: .move(edge: .top)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preparing your first morning ritual")
    }

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeOfDayGreeting)
                    .font(AppTheme.title2)
                    .foregroundStyle(AppTheme.textPrimary)
                if let name = profile?.name, !name.isEmpty {
                    Text(name)
                        .font(AppTheme.largeTitle)
                        .foregroundStyle(AppTheme.gold)
                }
            }
            Spacer()
            Text(timeOfDayEmoji)
                .font(.system(size: 40))
        }
    }

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Rise & shine"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Sweet dreams"
        }
    }

    private var timeOfDayEmoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "\u{1F31E}"
        case 12..<17: return "\u{2600}\u{FE0F}"
        case 17..<21: return "\u{1F305}"
        default: return "\u{1F319}"
        }
    }

    private var customAffirmationInput: some View {
        HStack(spacing: AppTheme.spacingMd) {
            TextField("Write your own affirmation...", text: $customAffirmationText, axis: .vertical)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1...3)

            Button {
                let trimmed = customAffirmationText.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                let affirmation = Affirmation(text: trimmed, generatedFor: Date())
                affirmation.favoriteType = 1
                affirmation.isFavorited = true
                affirmation.isCustom = true
                modelContext.insert(affirmation)
                customAffirmationText = ""
                HapticService.success()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(customAffirmationText.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.textTertiary : AppTheme.gold)
            }
            .disabled(customAffirmationText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
    }

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacingMd) {
            NavigationLink {
                AlarmListView()
            } label: {
                QuickActionCard(icon: "alarm.fill", title: "Alarms", color: AppTheme.sunsetOrange)
            }

            NavigationLink {
                FavoritesView()
            } label: {
                QuickActionCard(icon: "heart.fill", title: "Favorites", color: Color(hex: "E85D75"))
            }

            NavigationLink {
                SettingsView()
            } label: {
                QuickActionCard(icon: "gearshape.fill", title: "Settings", color: AppTheme.textSecondary)
            }
        }
        .buttonStyle(.bounce)
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.spacingMd) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            Text(title)
                .font(AppTheme.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingXl)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

