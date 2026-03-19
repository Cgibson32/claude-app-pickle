import SwiftUI

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise)

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: AppTheme.spacingSm) {
                    ForEach(0..<viewModel.totalSteps, id: \.self) { step in
                        Capsule()
                            .fill(step <= viewModel.currentStep ? AppTheme.gold : AppTheme.strokeLight)
                            .frame(width: step == viewModel.currentStep ? 24 : 8, height: 8)
                            .animation(AppTheme.bouncy, value: viewModel.currentStep)
                    }
                }
                .padding(.top, AppTheme.spacingXl)

                // Content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeView(viewModel: viewModel)
                        .tag(0)
                    NameEntryView(viewModel: viewModel)
                        .tag(1)
                    GoalsEntryView(viewModel: viewModel)
                        .tag(2)
                    EveningReflectionSetupView(viewModel: viewModel)
                        .tag(3)
                    FirstAlarmSetupView(viewModel: viewModel) {
                        viewModel.completeOnboarding(modelContext: modelContext)
                    }
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(AppTheme.bouncy, value: viewModel.currentStep)
            }
        }
        .preferredColorScheme(.dark)
    }
}
