import SwiftUI

struct AffirmationCardView: View {
    let text: String
    let index: Int
    let total: Int

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            Text(text)
                .font(AppTheme.title2)
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Text("\(index + 1) of \(total)")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textTertiary)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        AffirmationCardView(
            text: "I am a powerful basketball player who dominates the court with confidence and skill.",
            index: 0,
            total: 3
        )
    }
}
