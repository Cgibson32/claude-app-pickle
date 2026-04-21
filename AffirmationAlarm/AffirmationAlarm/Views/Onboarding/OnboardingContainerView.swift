import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext

    private let stepLabels = ["Welcome", "Your Name", "Goals & Reflection", "Set Alarm"]

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise)

            VStack(spacing: 0) {
                progressHeader
                    .padding(.top, AppTheme.spacingLg)
                    .padding(.horizontal, AppTheme.spacingXl)

                TabView(selection: $viewModel.currentStep) {
                    WelcomeView(viewModel: viewModel)
                        .tag(0)
                    NameEntryView(viewModel: viewModel)
                        .tag(1)
                    GoalsEntryView(viewModel: viewModel)
                        .tag(2)
                    FirstAlarmSetupView(viewModel: viewModel) {
                        viewModel.completeOnboarding(modelContext: modelContext)
                    }
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .scrollDisabled(true)
                .animation(AppTheme.bouncy, value: viewModel.currentStep)
            }
        }
        .preferredColorScheme(.dark)
    }

    /// Thin progress bar + "Step N of 4" label. Replaces the subtle dot
    /// indicator so users know exactly how long onboarding takes — clearer
    /// than capsule dots at a glance, especially from arm's length.
    private var progressHeader: some View {
        VStack(spacing: AppTheme.spacingSm) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.strokeLight)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.gold)
                        .frame(
                            width: geo.size.width * progress,
                            height: 4
                        )
                        .animation(AppTheme.bouncy, value: viewModel.currentStep)
                }
            }
            .frame(height: 4)

            HStack {
                Text("Step \(viewModel.currentStep + 1) of \(viewModel.totalSteps)")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textTertiary)
                Spacer()
                Text(stepLabels[viewModel.currentStep])
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    private var progress: CGFloat {
        CGFloat(viewModel.currentStep + 1) / CGFloat(viewModel.totalSteps)
    }
}
