import SwiftUI

struct WelcomeView: View {
    let viewModel: OnboardingViewModel
    @State private var sunriseScale: CGFloat = 0.3
    @State private var glowOffset: CGFloat = 40
    @State private var textOpacity: Double = 0

    var body: some View {
        VStack(spacing: AppTheme.spacing3xl) {
            Spacer()

            // Sunset with banded stripes
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.gold,
                                AppTheme.sunsetOrange,
                                AppTheme.sunsetRed,
                                AppTheme.sunsetDeepRed
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 160, height: 160)

                // Horizontal stripe bands for retro sunset look
                VStack(spacing: 4) {
                    Spacer()
                    ForEach(0..<5, id: \.self) { i in
                        Rectangle()
                            .fill(AppTheme.charcoalBlue)
                            .frame(height: CGFloat(2 + i))
                    }
                }
                .frame(width: 160, height: 160)
                .clipShape(Circle())

                // Horizon line
                Rectangle()
                    .fill(AppTheme.sunsetDeepRed.opacity(0.6))
                    .frame(width: 220, height: 2)
                    .offset(y: 40)
            }
            .frame(width: 160, height: 160)
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
