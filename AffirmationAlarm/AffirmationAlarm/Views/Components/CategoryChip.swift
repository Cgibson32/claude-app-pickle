import SwiftUI

struct CategoryChip: View {
    let category: GoalCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticService.selection()
            action()
        }) {
            HStack(spacing: AppTheme.spacingSm) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.rawValue)
                    .font(AppTheme.subheadline)
            }
            .foregroundStyle(isSelected ? AppTheme.charcoalBlue : AppTheme.textSecondary)
            .padding(.horizontal, AppTheme.spacingLg)
            .padding(.vertical, AppTheme.spacingMd)
            .background(isSelected ? AppTheme.gold : AppTheme.cardBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : AppTheme.strokeLight, lineWidth: 1)
            )
        }
        .buttonStyle(.bounce)
    }
}
