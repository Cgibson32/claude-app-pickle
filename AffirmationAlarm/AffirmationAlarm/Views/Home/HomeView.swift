import ActivityKit
import SwiftUI
import SwiftData

/// Home tab — a glance surface, not a workbench. Shows: greeting, next
/// alarm, tonight's intention, and (via toolbar) custom affirmation entry.
/// The alarm fires automatically without any user prep — there is no
/// "bedtime mode" to enable.
///
/// This view does NOT own a `NavigationStack` — `MainTabView` wraps each
/// tab in its own stack so deep navigation stays scoped per tab.
struct HomeView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \Alarm.hour) private var alarms: [Alarm]

    @State private var showAddAffirmation = false
    @State private var streakRefreshTrigger = 0

    /// Set to `true` by `OnboardingViewModel.completeOnboarding` while the
    /// first morning's audio is being rendered (~5-10s for Claude + TTS
    /// round-trips) and cleared when rendering finishes. The NextAlarmCard
    /// surfaces this as an inline "Preparing…" badge — no more full-width
    /// banner cluttering the layout.
    @AppStorage("isPreparingFirstMorning") private var isPreparingFirstMorning = false

    private var profile: UserProfile? { profiles.first }

    private var hasAPIKey: Bool {
        if let key = APIKeyConfiguration.getAPIKey(), !key.isEmpty { return true }
        return false
    }

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise)

            ScrollView {
                VStack(spacing: AppTheme.spacingXl) {
                    greetingSection

                    if !ActivityAuthorizationInfo().areActivitiesEnabled {
                        liveActivityWarning
                    }

                    if !hasAPIKey {
                        apiKeyWarning
                    }

                    let streak = StreakService.currentStreak()
                    let _ = streakRefreshTrigger // re-eval on trigger
                    if streak > 0 {
                        StreakRibbon(name: profile?.name ?? "", streak: streak)
                    }

                    NextAlarmCard(alarms: alarms, isPreparing: isPreparingFirstMorning)

                    IntentionCard()

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
        .onReceive(NotificationCenter.default.publisher(for: .didCompleteMorningPlayback)) { _ in
            streakRefreshTrigger &+= 1
        }
    }

    private var liveActivityWarning: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            HStack(spacing: AppTheme.spacingSm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppTheme.sunsetOrange)
                Text("Stop & Snooze won't show")
                    .font(AppTheme.headline)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Text("Live Activities are turned off. Your alarm needs this to show Stop and Snooze buttons on the lock screen.")
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(AppTheme.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.gold)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(AppTheme.gold.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.sunsetOrange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
    }

    private var apiKeyWarning: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            HStack(spacing: AppTheme.spacingSm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppTheme.sunsetOrange)
                Text("Affirmations not personalized")
                    .font(AppTheme.headline)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Text("No Claude API key found. Your alarm will play generic affirmations instead of ones tailored to your goals. Add your key in Settings → Diagnostics.")
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.sunsetOrange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
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
