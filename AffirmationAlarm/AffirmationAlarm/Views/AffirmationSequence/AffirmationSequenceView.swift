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
                            .tint(.white)
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
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(.white))
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
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
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
                .foregroundColor(.white.opacity(0.8))
                .symbolEffect(.pulse)

            Text("Rise & Shine")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }

    private var greetingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sunrise.fill")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.8))
                .symbolEffect(.breathe)

            Text("Good Morning")
                .font(.title)
                .fontWeight(.light)
                .foregroundColor(.white.opacity(0.8))

            Text(viewModel.userName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }

    private var closingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))

            Text(viewModel.closingMessage)
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            Text(viewModel.userName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }

    private var completeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.8))

            Text("You're ready to\nconquer the day!")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
    }

    private var backgroundStyle: GradientBackground.GradientStyle {
        switch viewModel.phase {
        case .loading, .alarmSound, .greeting:
            return .calm
        case .affirmation, .breathing:
            return .sunrise
        case .closing, .complete:
            return .warmEvening
        }
    }
}

#Preview {
    AffirmationSequenceView()
        .modelContainer(for: [UserProfile.self, Affirmation.self], inMemory: true)
}
