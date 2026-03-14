import SwiftUI

struct OnboardingFlowView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userService: UserService

    var body: some View {
        ZStack {
            PickleProColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                if viewModel.currentStep > 0 && viewModel.currentStep < viewModel.totalSteps - 1 {
                    HStack(spacing: 8) {
                        Button(action: { viewModel.previousStep() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        PPProgressBar(progress: viewModel.progress)
                            .padding(.horizontal, 8)

                        Text("\(viewModel.currentStep)/\(viewModel.totalSteps - 1)")
                            .font(PickleProTypography.caption)
                            .foregroundColor(PickleProColors.textSecondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                // Content
                TabView(selection: $viewModel.currentStep) {
                    OnboardingWelcomeStep()
                        .tag(0)
                    OnboardingMissionStep()
                        .tag(1)
                    OnboardingGrowthStep()
                        .tag(2)
                    OnboardingNameStep(name: $viewModel.name)
                        .tag(3)
                    OnboardingExperienceStep(level: $viewModel.experienceLevel)
                        .tag(4)
                    OnboardingFrequencyStep(
                        frequency: $viewModel.playFrequency,
                        preference: $viewModel.playPreference
                    )
                        .tag(5)
                    OnboardingStrugglesStep(selected: $viewModel.selectedStruggles)
                        .tag(6)
                    OnboardingTechnicalStep(selected: $viewModel.selectedTechnicalWeaknesses)
                        .tag(7)
                    OnboardingMentalStep(selected: $viewModel.selectedMentalWeaknesses)
                        .tag(8)
                    OnboardingGoalsStep(selected: $viewModel.selectedGoals)
                        .tag(9)
                    OnboardingFrustrationsStep(selected: $viewModel.selectedFrustrations)
                        .tag(10)
                    OnboardingSummaryStep(viewModel: viewModel)
                        .tag(11)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

                // Bottom button
                VStack(spacing: 16) {
                    if viewModel.currentStep == viewModel.totalSteps - 1 {
                        PPButton(title: "Begin My Journey", style: .primary) {
                            let profile = viewModel.buildProfile()
                            userService.completeOnboarding(profile: profile)
                            withAnimation(.easeInOut(duration: 0.5)) {
                                appState.hasCompletedOnboarding = true
                            }
                        }
                    } else {
                        PPButton(
                            title: viewModel.currentStep == 0 ? "Get Started" : "Continue",
                            style: .primary
                        ) {
                            viewModel.nextStep()
                        }
                        .opacity(viewModel.canProceed() ? 1 : 0.5)
                        .disabled(!viewModel.canProceed())
                    }

                    if viewModel.currentStep > 2 {
                        Button("Skip") {
                            viewModel.nextStep()
                        }
                        .font(PickleProTypography.subheadline)
                        .foregroundColor(PickleProColors.textTertiary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
