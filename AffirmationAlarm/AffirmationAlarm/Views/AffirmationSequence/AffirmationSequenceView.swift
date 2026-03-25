import SwiftUI
import SwiftData

struct AffirmationSequenceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var viewModel = AffirmationSequenceViewModel()

    var body: some View {
        ZStack {
            gradientForPhase
                .animation(AppTheme.gentle, value: viewModel.phase)

            VStack {
                // Skip button
                HStack {
                    Spacer()
                    if viewModel.phase != .complete {
                        Button {
                            viewModel.skip()
                        } label: {
                            Text("Skip")
                                .font(AppTheme.subheadline)
                                .foregroundStyle(AppTheme.textTertiary)
                                .padding(.horizontal, AppTheme.spacingLg)
                                .padding(.vertical, AppTheme.spacingSm)
                                .background(AppTheme.cardBackground)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(AppTheme.spacingXl)

                Spacer()

                // Phase content
                Group {
                    switch viewModel.phase {
                    case .loading:
                        ProgressView()
                            .tint(AppTheme.gold)
                            .scaleEffect(1.5)

                    case .alarmSound:
                        alarmSoundView

                    case .greeting:
                        greetingView

                    case .affirmation(let index):
                        if index < viewModel.affirmations.count {
                            AffirmationCardView(
                                text: viewModel.affirmations[index].text,
                                index: index + 1,
                                total: viewModel.affirmations.count
                            )
                        }

                    case .breathing:
                        BreathingPromptView()

                    case .closing:
                        closingView

                    case .complete:
                        completionView
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

                if viewModel.error != nil {
                    Text("Using offline affirmations")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(.horizontal, AppTheme.spacingLg)
                        .padding(.vertical, AppTheme.spacingSm)
                        .background(AppTheme.cardBackground)
                        .clipShape(Capsule())
                        .padding(.top, AppTheme.spacingSm)
                }

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .task {
            if let profile = profiles.first {
                await viewModel.start(profile: profile, modelContext: modelContext)
            }
        }
    }

    private var gradientForPhase: some View {
        Group {
            switch viewModel.phase {
            case .loading, .alarmSound:
                GradientBackground(style: .sunrise)
            case .greeting, .affirmation:
                GradientBackground(style: .energy)
            case .breathing, .closing:
                GradientBackground(style: .glow)
            case .complete:
                GradientBackground(style: .energy)
            }
        }
    }

    private var alarmSoundView: some View {
        VStack(spacing: AppTheme.spacingXl) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.sunsetOrange)
                .symbolEffect(.pulse)

            Text("Good Morning")
                .font(AppTheme.title2)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var greetingView: some View {
        VStack(spacing: AppTheme.spacingLg) {
            Text("Rise & Shine")
                .font(AppTheme.largeTitle)
                .foregroundStyle(AppTheme.gold)

            if let name = profiles.first?.name, !name.isEmpty {
                Text(name)
                    .font(AppTheme.title)
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
    }

    private var closingView: some View {
        VStack(spacing: AppTheme.spacingXl) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.gold)

            Text(viewModel.closingMessage)
                .font(AppTheme.title2)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)

            if let name = profiles.first?.name, !name.isEmpty {
                Text(name)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, AppTheme.spacingXxl)
    }

    private var completionView: some View {
        VStack(spacing: AppTheme.spacingXxl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.gold)

            Text("You're all set!")
                .font(AppTheme.title)
                .foregroundStyle(AppTheme.textPrimary)

            if let streak = viewModel.streakInfo, streak.current > 0 {
                HStack(spacing: AppTheme.spacingSm) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.sunsetOrange, AppTheme.gold],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    Text("\(streak.current) day streak")
                        .font(AppTheme.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(.horizontal, AppTheme.spacingXl)
                .padding(.vertical, AppTheme.spacingMd)
                .background(AppTheme.cardBackground)
                .clipShape(Capsule())

                if let milestone = streak.milestone,
                   let message = StreakService.milestoneMessage(for: milestone) {
                    Text(message)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.gold)
                        .multilineTextAlignment(.center)
                }
            }

            Button("Done") {
                dismiss()
            }
            .buttonStyle(PillButtonStyle())
        }
        .padding(.horizontal, AppTheme.spacingXxl)
    }
}
