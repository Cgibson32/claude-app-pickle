import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showButton = false
    @State private var iconFloat = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "sunrise.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppTheme.textPrimary)
                    .symbolEffect(.pulse)
                    .opacity(showIcon ? 1 : 0)
                    .scaleEffect(showIcon ? 1 : 0.5)
                    .offset(y: iconFloat ? -6 : 6)

                Text("Affirmation Alarm")
                    .font(AppTheme.largeTitle)
                    .foregroundColor(AppTheme.textPrimary)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 15)

                Text("Wake up inspired.\nEvery morning.")
                    .font(AppTheme.title3)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(showSubtitle ? 1 : 0)
                    .offset(y: showSubtitle ? 0 : 10)
            }

            Spacer()

            VStack(spacing: 16) {
                Text("Start each day with personalized affirmations\ntailored to your goals and dreams.")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(showButton ? 1 : 0)

                Button(action: {
                    HapticService.medium()
                    onContinue()
                }) {
                    Text("Get Started")
                        .font(AppTheme.headline)
                        .foregroundColor(AppTheme.accentText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(AppTheme.buttonBackground))
                }
                .padding(.horizontal, 40)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 20)
            }

            Spacer()
                .frame(height: 60)
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showIcon = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.35)) {
                showTitle = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.55)) {
                showSubtitle = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.75)) {
                showButton = true
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(0.8)) {
                iconFloat = true
            }
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        WelcomeView(onContinue: {})
    }
}
