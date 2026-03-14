import SwiftUI

struct PPQuoteCard: View {
    let quote: String
    var attribution: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            Text("\u{201C}\(quote)\u{201D}")
                .font(PickleProTypography.quote)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .italic()

            if let attribution = attribution {
                Text("— \(attribution)")
                    .font(PickleProTypography.caption)
                    .foregroundColor(PickleProColors.textTertiary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(PickleProColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(PickleProColors.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct PPSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"

    var body: some View {
        HStack {
            Text(title)
                .font(PickleProTypography.title3)
                .foregroundColor(.white)
            Spacer()
            if let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(PickleProTypography.subheadline)
                        .foregroundColor(PickleProColors.accent)
                }
            }
        }
    }
}
