import SwiftUI

struct CategoryChip: View {
    let category: GoalCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white : Color.white.opacity(0.25))
            )
            .foregroundColor(isSelected ? .black : .white)
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
