import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "sunrise.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                    .symbolEffect(.breathe)

                Text("Affirmation Alarm")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Wake up inspired.\nEvery morning.")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 16) {
                Text("Start each day with personalized affirmations\ntailored to your goals and dreams.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(.white))
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
