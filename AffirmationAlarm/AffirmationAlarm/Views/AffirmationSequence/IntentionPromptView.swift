import SwiftUI

struct IntentionPromptView: View {
    @Binding var text: String
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "scope")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.gold)
                .symbolEffect(.pulse)

            Text("What's your one\nintention for today?")
                .font(AppTheme.title3)
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)

            TextField("Today I will...", text: $text)
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.textPrimary)
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
        GradientBackground(style: .energy)
        IntentionPromptView(text: .constant(""))
    }
}
