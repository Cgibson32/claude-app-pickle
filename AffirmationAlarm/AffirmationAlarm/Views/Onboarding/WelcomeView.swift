import SwiftUI

struct WelcomeView: View {
    let viewModel: OnboardingViewModel
    @State private var sunriseScale: CGFloat = 0.3
    @State private var textOpacity: Double = 0

    var body: some View {
        VStack(spacing: AppTheme.spacing3xl) {
            Spacer()

            // App icon
            Image("AppIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(color: AppTheme.sunsetOrange.opacity(0.4), radius: 20, y: 8)
                .scaleEffect(sunriseScale)

            VStack(spacing: AppTheme.spacingLg) {
                Text("Rise with Purpose")
                    .font(AppTheme.largeTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Start every morning with personalized\naffirmations that inspire your day")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(textOpacity)

            Spacer()

            Button("Get Started") {
                HapticService.medium()
                viewModel.advance()
            }
            .buttonStyle(PillButtonStyle())
            .opacity(textOpacity)

            Spacer()
                .frame(height: AppTheme.spacing3xl)
        }
        .padding(.horizontal, AppTheme.spacingXxl)
        .onAppear {
            withAnimation(AppTheme.bouncy.delay(0.2)) {
                sunriseScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                textOpacity = 1.0
            }
        }
    }
}
