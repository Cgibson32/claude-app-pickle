import SwiftUI

struct ShareableAffirmationCard: View {
    let text: String

    var body: some View {
        VStack(spacing: AppTheme.spacingLg) {
            Image(systemName: "quote.opening")
                .font(.system(size: 24))
                .foregroundStyle(AppTheme.gold.opacity(0.6))

            Text(text)
                .font(AppTheme.title3)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("Affirmation Alarm")
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .padding(AppTheme.spacing3xl)
        .frame(width: 400)
        .background(
            LinearGradient(
                colors: [AppTheme.charcoalBlue, AppTheme.deepPlum],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
    }
}
