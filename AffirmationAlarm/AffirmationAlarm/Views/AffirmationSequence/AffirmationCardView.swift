import SwiftUI

struct AffirmationCardView: View {
    let text: String
    let index: Int
    let total: Int

    @State private var appeared = false

    var body: some View {
        VStack(spacing: AppTheme.spacingXxl) {
            Text("\(index) of \(total)")
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textTertiary)

            Text(text)
                .font(AppTheme.title2)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, AppTheme.spacingXl)
                .scaleEffect(appeared ? 1.0 : 0.85)
                .opacity(appeared ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(AppTheme.bouncy) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}
