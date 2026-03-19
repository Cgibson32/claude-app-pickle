import SwiftUI

struct GratitudePromptView: View {
    @Binding var text: String
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.warmAmber)
                .symbolEffect(.pulse)

            Text("What are you\ngrateful for today?")
                .font(AppTheme.title3)
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)

            TextField("I'm grateful for...", text: $text, axis: .vertical)
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(3...5)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.inputBackground)
                )
                .padding(.horizontal, 20)

            Text("Optional — skip to continue")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }
}

#Preview {
    ZStack {
        GradientBackground(style: .sunrise)
        GratitudePromptView(text: .constant(""))
    }
}
