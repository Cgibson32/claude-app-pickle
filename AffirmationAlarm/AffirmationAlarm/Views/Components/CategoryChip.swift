import SwiftUI

struct CategoryChip: View {
    let category: GoalCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                Text(category.rawValue)
                    .font(AppTheme.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? AppTheme.buttonBackground : AppTheme.cardBackground)
            )
            .foregroundColor(isSelected ? AppTheme.accentText : AppTheme.textPrimary)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    ZStack {
        GradientBackground()
        VStack(spacing: 12) {
            CategoryChip(category: .successCareer, isSelected: true) {}
            CategoryChip(category: .healthWellness, isSelected: false) {}
        }
    }
}
