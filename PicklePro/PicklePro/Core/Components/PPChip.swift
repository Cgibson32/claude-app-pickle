import SwiftUI

struct PPChip: View {
    let title: String
    let isSelected: Bool
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            Text(title)
                .font(PickleProTypography.subheadline)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isSelected
                        ? AnyShapeStyle(PickleProColors.accentGradient)
                        : AnyShapeStyle(PickleProColors.surfaceLight)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.clear : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct PPSelectionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(PickleProTypography.callout)
                    .foregroundColor(isSelected ? .black : .white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                isSelected
                    ? AnyShapeStyle(PickleProColors.accentGradient)
                    : AnyShapeStyle(PickleProColors.cardBackground)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.clear : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
