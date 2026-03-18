import SwiftUI

struct BreathingPromptView: View {
    @State private var isExpanded = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Text("Take a deep breath\ninto your heart...")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)

            // Breathing circle
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: isExpanded ? 100 : 40
                        )
                    )
                    .frame(width: isExpanded ? 200 : 80, height: isExpanded ? 200 : 80)

                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .frame(width: isExpanded ? 200 : 80, height: isExpanded ? 200 : 80)

                Image(systemName: "heart.fill")
                    .font(.system(size: isExpanded ? 36 : 20))
                    .foregroundColor(.white)
            }
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isExpanded)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
            // Start breathing animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isExpanded = true
            }
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        BreathingPromptView()
    }
}
