import SwiftUI
import SwiftData

struct AffirmationSequenceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AffirmationSequenceViewModel()
    @State private var showDismissButton = false

    var body: some View {
        ZStack {
            // Animated gradient background
            GradientBackground(style: backgroundStyle)
                .animation(.easeInOut(duration: 2), value: viewModel.phase)

            VStack {
                Spacer()

                // Phase content
                Group {
                    switch viewModel.phase {
                    case .loading:
                        ProgressView()
                            .tint(AppTheme.warmWhite)
                            .scaleEffect(1.5)

                    case .alarmSound:
                        alarmSoundView

                    case .greeting:
                        greetingView

                    case .affirmation(let index):
                        if index < viewModel.affirmations.count {
                            AffirmationCardView(
                                text: viewModel.affirmations[index],
                                index: index,
                                total: viewModel.affirmations.count
                            )
                            .id("affirmation-\(index)")
                        }

                    case .breathing:
                        BreathingPromptView()

                    case .closing:
                        closingView

                    case .complete:
                        completeView
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

                Spacer()

                // Skip / Dismiss controls
                if viewModel.phase == .complete {
                    Button(action: { dismiss() }) {
                        Text("Start My Day")
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.accentText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(AppTheme.buttonBackground))
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if showDismissButton {
                    Button(action: {
                        viewModel.stopSpeech()
                        dismiss()
                    }) {
                        Text("Skip")
                            .font(AppTheme.subheadline)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            viewModel.loadAndStart(modelContext: modelContext)
            // Show skip button after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { showDismissButton = true }
            }
        }
        .onDisappear {
            viewModel.stopSpeech()
        }
        .statusBarHidden(true)
    }

    // MARK: - Subviews

    private var alarmSoundView: some View {
        VStack(spacing: 20) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.textSecondary)
                .symbolEffect(.pulse)

            Text("Rise & Shine")
                .font(AppTheme.title2)
                .foregroundColor(AppTheme.textPrimary)
        }
    }

    private var greetingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sunrise.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.textSecondary)
                .symbolEffect(.pulse)

            Text("Good Morning")
                .font(AppTheme.heading(28, weight: .light))
                .foregroundColor(AppTheme.textSecondary)

            Text(viewModel.userName)
                .font(AppTheme.largeTitle)
                .foregroundColor(AppTheme.textPrimary)
        }
    }

    private var closingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textSecondary)

            Text(viewModel.closingMessage)
                .font(AppTheme.title3)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            Text(viewModel.userName)
                .font(AppTheme.title)
                .foregroundColor(AppTheme.textPrimary)
        }
    }

    private var shareText: String {
        viewModel.affirmations.map { "\"\($0)\"" }.joined(separator: "\n\n")
            + "\n\n— Affirmation Alarm"
    }

    private var completeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.textSecondary)

            Text("You're ready to\nconquer the day!")
                .font(AppTheme.title2)
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)

            // Streak badge
            if viewModel.streakCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(AppTheme.sunsetOrange)
                    Text("\(viewModel.streakCount) day streak")
                        .font(AppTheme.subheadline)
                        .foregroundColor(AppTheme.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(AppTheme.cardBackground))
            }

            // Milestone celebration
            if StreakService.shared.isMilestone(viewModel.streakCount),
               let message = StreakService.shared.milestoneMessage(viewModel.streakCount) {
                Text(message)
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.gold)
                    .transition(.scale.combined(with: .opacity))
            }

            Button {
                if let first = viewModel.affirmations.first {
                    AffirmationImageRenderer.share(text: first)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Affirmations")
                }
                .font(AppTheme.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(
                    Capsule()
                        .stroke(AppTheme.strokeLight, lineWidth: 1)
                )
            }
        }
    }

    private var backgroundStyle: GradientBackground.GradientStyle {
        switch viewModel.phase {
        case .loading, .alarmSound, .greeting:
            return .glow
        case .affirmation, .breathing:
            return .sunrise
        case .closing, .complete:
            return .energy
        }
    }
}

#Preview {
    AffirmationSequenceView()
        .modelContainer(for: [UserProfile.self, Affirmation.self], inMemory: true)
}
