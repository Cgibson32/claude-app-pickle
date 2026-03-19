import SwiftUI

struct JournalDayCard: View {
    let day: JournalDay

    private let moods = ["😔", "😐", "🙂", "😊", "🤩"]

    private var dateText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day.id) {
            return "Today"
        } else if calendar.isDateInYesterday(day.id) {
            return "Yesterday"
        } else {
            return DateFormatters.dateFormatter.string(from: day.id)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(dateText)
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                if day.completedSequence {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.accent)
                        .font(.system(size: 16))
                }
            }

            // Intention
            if let intention = day.intention {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "scope")
                        .foregroundColor(AppTheme.gold)
                        .font(.system(size: 14))
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Intention")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.textTertiary)
                        Text(intention.text)
                            .font(AppTheme.subheadline)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }

            // Affirmations
            if !day.affirmations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(AppTheme.warmAmber)
                            .font(.system(size: 14))
                            .frame(width: 20)
                        Text("Affirmations")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.textTertiary)
                    }

                    ForEach(day.affirmations) { affirmation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 8))
                                .foregroundColor(AppTheme.textTertiary)
                                .padding(.top, 3)
                            Text(affirmation.text)
                                .font(AppTheme.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.leading, 26)
                    }
                }
            }

            // Gratitude
            if let gratitude = day.gratitude {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(AppTheme.warmAmber)
                        .font(.system(size: 14))
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Grateful for")
                            .font(AppTheme.caption)
                            .foregroundColor(AppTheme.textTertiary)
                        Text(gratitude.text)
                            .font(AppTheme.subheadline)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }

            // Evening reflection
            if let reflection = day.eveningReflection {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(AppTheme.gold)
                        .font(.system(size: 14))
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Evening")
                                .font(AppTheme.caption)
                                .foregroundColor(AppTheme.textTertiary)
                            if reflection.mood >= 0 && reflection.mood < moods.count {
                                Text(moods[reflection.mood])
                                    .font(.system(size: 14))
                            }
                        }
                        if !reflection.goodThing.isEmpty {
                            Text(reflection.goodThing)
                                .font(AppTheme.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        if !reflection.gratitude.isEmpty {
                            Text("Grateful: \(reflection.gratitude)")
                                .font(AppTheme.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
        )
    }
}
