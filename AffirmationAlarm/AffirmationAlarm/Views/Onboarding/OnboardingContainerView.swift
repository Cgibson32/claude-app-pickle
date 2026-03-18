import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            GradientBackground()

            VStack {
                // Progress indicator
                if viewModel.currentStep > 0 {
                    HStack {
                        Button(action: { viewModel.previousStep() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.textPrimary)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            ForEach(0..<viewModel.totalSteps, id: \.self) { step in
                                Circle()
                                    .fill(step <= viewModel.currentStep ? AppTheme.accent : AppTheme.textTertiary)
                                    .frame(width: 8, height: 8)
                            }
                        }

                        Spacer()

                        // Invisible balance element
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                // Step content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeView(onContinue: { viewModel.nextStep() })
                        .tag(0)

                    NameEntryView(
                        name: $viewModel.name,
                        onContinue: { viewModel.nextStep() }
                    )
                    .tag(1)

                    GoalsEntryView(
                        freeformGoals: $viewModel.freeformGoals,
                        selectedCategories: $viewModel.selectedCategories,
                        affirmationCount: $viewModel.affirmationCount,
                        onContinue: { viewModel.nextStep() }
                    )
                    .tag(2)

                    FirstAlarmSetupView(
                        alarmTime: $viewModel.alarmTime,
                        selectedDays: $viewModel.selectedDays,
                        selectedSound: $viewModel.selectedSound,
                        onComplete: {
                            viewModel.completeOnboarding(modelContext: modelContext)
                        }
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
        }
    }
}

#Preview {
    OnboardingContainerView()
        .modelContainer(for: [UserProfile.self, Alarm.self, Affirmation.self], inMemory: true)
}
