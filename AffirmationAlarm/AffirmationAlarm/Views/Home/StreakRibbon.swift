import SwiftUI

/// Soft pill above the Next Alarm card celebrating consecutive
/// successful mornings. Hidden when streak is 0 — silence is gentler
/// than implying absence. Never shames a missed day.
struct StreakRibbon: View {
    let name: String
    let streak: Int

    var body: some View {
        HStack(spacing: AppTheme.spacingSm) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.gold)
            Text(streakText)
                .font(AppTheme.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppTheme.spacingLg)
        .padding(.vertical, AppTheme.spacingSm)
        .background(AppTheme.gold.opacity(0.10))
        .clipShape(Capsule())
        .overlay(
            Capsule().strokeBorder(AppTheme.gold.opacity(0.20), lineWidth: 1)
        )
    }

    private var streakText: String {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let suffix = trimmedName.isEmpty ? "" : ", \(trimmedName)"
        if streak == 1 { return "Your first morning\(suffix)" }
        return "\(streak) mornings in a row\(suffix)"
    }
}
