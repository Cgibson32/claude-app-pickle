import SwiftUI

struct WelcomeView: View {
    let viewModel: OnboardingViewModel
    @State private var sunriseScale: CGFloat = 0.3
    @State private var textOpacity: Double = 0

    var body: some View {
        VStack(spacing: AppTheme.spacing3xl) {
            Spacer()

            // Animated sunrise icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.gold, AppTheme.sunsetOrange.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(sunriseScale)

                Image(systemName: "sunrise.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.gold, AppTheme.sunsetOrange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(sunriseScale)
            }

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
