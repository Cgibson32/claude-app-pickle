import SwiftUI

struct EveningReflectionSetupView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: AppTheme.spacing3xl) {
            Spacer()

            VStack(spacing: AppTheme.spacingLg) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.gold, AppTheme.warmAmber],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Evening Reflection")
                    .font(AppTheme.title)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("End your day with gratitude.\nA quick check-in to reflect on what went well.")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Toggle card
            VStack(spacing: AppTheme.spacingLg) {
                Toggle(isOn: $viewModel.eveningReflectionEnabled) {
                    Text("Enable evening reminders")
                        .font(AppTheme.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .tint(AppTheme.sunsetOrange)

                if viewModel.eveningReflectionEnabled {
                    DatePicker(
                        "Reminder time",
                        selection: Binding(
                            get: {
                                Calendar.current.date(
                                    from: DateComponents(hour: viewModel.eveningReflectionHour, minute: viewModel.eveningReflectionMinute)
                                ) ?? Date()
                            },
                            set: { date in
                                viewModel.eveningReflectionHour = Calendar.current.component(.hour, from: date)
                                viewModel.eveningReflectionMinute = Calendar.current.component(.minute, from: date)
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 120)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(AppTheme.spacingXl)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
            .animation(AppTheme.bouncy, value: viewModel.eveningReflectionEnabled)

            Spacer()

            Button("Continue") {
                HapticService.medium()
                viewModel.advance()
            }
            .buttonStyle(PillButtonStyle())

            Spacer()
                .frame(height: AppTheme.spacing3xl)
        }
        .padding(.horizontal, AppTheme.spacingXxl)
    }
}
