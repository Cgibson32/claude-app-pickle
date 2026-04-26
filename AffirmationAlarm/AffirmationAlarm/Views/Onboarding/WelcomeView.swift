import SwiftUI

struct WelcomeView: View {
    let viewModel: OnboardingViewModel
    @State private var sunriseScale: CGFloat = 0.3
    @State private var glowOffset: CGFloat = 40
    @State private var textOpacity: Double = 0

    var body: some View {
        VStack(spacing: AppTheme.spacing3xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.gold.opacity(0.6),
                                AppTheme.warmAmber.opacity(0.3),
                                AppTheme.sunsetOrange.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .blur(radius: 20)

                Circle()
                    .fill(AppTheme.gold.opacity(0.25))
                    .frame(width: 80, height: 80)

                Circle()
                    .strokeBorder(AppTheme.gold.opacity(0.15), lineWidth: 1)
                    .frame(width: 130, height: 130)

                Circle()
                    .strokeBorder(AppTheme.gold.opacity(0.08), lineWidth: 1)
                    .frame(width: 180, height: 180)
            }
            .frame(width: 240, height: 240)
            .offset(y: glowOffset)
            .scaleEffect(sunriseScale)

            VStack(spacing: AppTheme.spacingLg) {
                Text("Rise with Purpose")
                    .font(AppTheme.largeTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Start every morning with personalized affirmations that inspire your day")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
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
                glowOffset = 0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                textOpacity = 1.0
            }
        }
    }
}
