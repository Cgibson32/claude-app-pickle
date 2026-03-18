import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "sunrise.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppTheme.textPrimary)
                    .symbolEffect(.breathe)

                Text("Affirmation Alarm")
                    .font(AppTheme.largeTitle)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Wake up inspired.\nEvery morning.")
                    .font(AppTheme.title3)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 16) {
                Text("Start each day with personalized affirmations\ntailored to your goals and dreams.")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Button(action: onContinue) {
                    Text("Get Started")
                        .font(AppTheme.headline)
                        .foregroundColor(AppTheme.accentText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(AppTheme.buttonBackground))
                }
                .padding(.horizontal, 40)
            }

            Spacer()
                .frame(height: 60)
        }
        .padding()
    }
}

#Preview {
    ZStack {
        GradientBackground()
        WelcomeView(onContinue: {})
    }
}
