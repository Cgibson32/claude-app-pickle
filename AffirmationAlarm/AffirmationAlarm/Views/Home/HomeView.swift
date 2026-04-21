import SwiftUI
import SwiftData

/// Home tab — a glance surface, not a workbench. Shows: greeting, next
/// alarm (with inline "preparing" state during the first-morning render),
/// sleep mode entry, and today's affirmations. Custom affirmation entry
/// is a sheet triggered from the toolbar, so the home screen can focus
/// on *output* without a persistent input field stealing vertical space.
///
/// This view does NOT own a `NavigationStack` — `MainTabView` wraps each
/// tab in its own stack so deep navigation stays scoped per tab.
struct HomeView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \Alarm.hour) private var alarms: [Alarm]

    @State private var showSleepMode = false
    @State private var showAddAffirmation = false

    /// Set to `true` by `OnboardingViewModel.completeOnboarding` while the
    /// first morning's audio is being rendered (~5-10s for Claude + TTS
    /// round-trips) and cleared when rendering finishes. The NextAlarmCard
    /// surfaces this as an inline "Preparing…" badge — no more full-width
    /// banner cluttering the layout.
    @AppStorage("isPreparingFirstMorning") private var isPreparingFirstMorning = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise)

            ScrollView {
                VStack(spacing: AppTheme.spacingXl) {
                    greetingSection

                    NextAlarmCard(alarms: alarms, isPreparing: isPreparingFirstMorning)

                    if alarms.contains(where: \.isEnabled) {
                        sleepModeCard
                    }

                    Spacer().frame(height: AppTheme.spacingXl)
                }
                .padding(.horizontal, AppTheme.spacingXl)
                .padding(.top, AppTheme.spacingLg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddAffirmation = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(AppTheme.gold)
                }
                .accessibilityLabel("Add custom affirmation")
            }
        }
        .sheet(isPresented: $showAddAffirmation) {
            AddAffirmationSheet()
        }
        .fullScreenCover(isPresented: $showSleepMode) {
            SleepModeView()
        }
    }

    private var sleepModeCard: some View {
        Button {
            showSleepMode = true
        } label: {
            HStack(spacing: AppTheme.spacingMd) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.gold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Bedtime")
                        .font(AppTheme.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Hands-free affirmations when the alarm rings. Otherwise, slide to stop and they'll play automatically.")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(AppTheme.spacingLg)
            .background(AppTheme.gold.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                    .strokeBorder(AppTheme.gold.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.bounce)
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
}
