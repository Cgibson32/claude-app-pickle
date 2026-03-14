import SwiftUI

struct PPButton: View {
    let title: String
    var style: ButtonStyle = .primary
    let action: () -> Void

    enum ButtonStyle {
        case primary, secondary, outline, teal
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PickleProTypography.headline)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(backgroundView)
                .cornerRadius(14)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .black
        case .secondary: return PickleProColors.accent
        case .outline: return .white
        case .teal: return .black
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            PickleProColors.accentGradient
        case .secondary:
            PickleProColors.cardBackgroundElevated
        case .outline:
            Color.clear
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        case .teal:
            PickleProColors.tealGradient
        }
    }
}

struct PPIconButton: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(PickleProColors.accent)
                    .frame(width: 40, height: 40)
                    .background(PickleProColors.accent.opacity(0.15))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(PickleProTypography.headline)
                        .foregroundColor(.white)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(PickleProTypography.caption)
                            .foregroundColor(PickleProColors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(PickleProColors.textTertiary)
            }
            .padding(16)
            .background(PickleProColors.cardBackground)
            .cornerRadius(14)
        }
    }
}
