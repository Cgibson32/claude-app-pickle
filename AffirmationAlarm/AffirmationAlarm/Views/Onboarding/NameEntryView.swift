import SwiftUI

struct NameEntryView: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: AppTheme.spacing3xl) {
            Spacer()

            VStack(spacing: AppTheme.spacingLg) {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.gold)

                Text("What's your name?")
                    .font(AppTheme.title)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("To personalize your mornings")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TextField("Your name", text: $viewModel.name)
                .font(AppTheme.title3)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(AppTheme.spacingLg)
                .background(AppTheme.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                .focused($isFocused)
                .onSubmit {
                    if viewModel.canAdvance { viewModel.advance() }
                }

            Spacer()

            Button("Continue") {
                HapticService.medium()
                isFocused = false
                viewModel.advance()
            }
            .buttonStyle(PillButtonStyle())
            .disabled(!viewModel.canAdvance)
            .opacity(viewModel.canAdvance ? 1.0 : 0.5)

            Spacer()
                .frame(height: AppTheme.spacing3xl)
        }
        .padding(.horizontal, AppTheme.spacingXxl)
        .onAppear { isFocused = true }
    }
}
