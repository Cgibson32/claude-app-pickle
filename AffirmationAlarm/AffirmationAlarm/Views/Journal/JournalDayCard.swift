import SwiftUI

struct JournalDayCard: View {
    let day: JournalDay

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            // Date header
            HStack {
                Text(AppDateFormatters.dateFormatter.string(from: day.date))
                    .font(AppTheme.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                if day.completed {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppTheme.gold)
                }
            }

            // Intentions
            if let intention = day.intentions.first {
                JournalSection(icon: "target", color: AppTheme.sunsetOrange) {
                    Text(intention.text)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }

            // Affirmations
            if !day.affirmations.isEmpty {
                JournalSection(icon: "sparkles", color: AppTheme.gold) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(day.affirmations) { affirmation in
                            Text(affirmation.text)
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineSpacing(2)
                        }
                    }
                }
            }

            // Gratitude
            if let gratitude = day.gratitudeEntries.first {
                JournalSection(icon: "heart.fill", color: Color(hex: "E85D75")) {
                    Text(gratitude.text)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }

            // Evening reflection
            if let reflection = day.reflection {
                JournalSection(icon: "moon.stars.fill", color: AppTheme.warmAmber) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mood: \(AppConstants.moodEmojis[min(reflection.mood, 4)])")
                            .font(AppTheme.subheadline)
                        if !reflection.goodThing.isEmpty {
                            Text(reflection.goodThing)
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                }
            }
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
    }
}

struct JournalSection<Content: View>: View {
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingMd) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 20)
            content
        }
    }
}
