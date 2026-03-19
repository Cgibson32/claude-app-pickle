import SwiftUI
import SwiftData

struct JournalView: View {
    @Query(sort: \Affirmation.generatedFor, order: .reverse) private var affirmations: [Affirmation]
    @Query(sort: \GratitudeEntry.date, order: .reverse) private var gratitudeEntries: [GratitudeEntry]
    @Query(sort: \DailyIntention.date, order: .reverse) private var intentions: [DailyIntention]
    @Query(sort: \EveningReflection.date, order: .reverse) private var reflections: [EveningReflection]
    @Query(sort: \SequenceCompletion.date, order: .reverse) private var completions: [SequenceCompletion]

    private var groupedDays: [JournalDay] {
        var dayMap: [String: JournalDay] = [:]

        for a in affirmations {
            let key = AppDateFormatters.dayKey(for: a.generatedFor)
            dayMap[key, default: JournalDay(date: a.generatedFor, dayKey: key)].affirmations.append(a)
        }
        for g in gratitudeEntries {
            let key = AppDateFormatters.dayKey(for: g.date)
            dayMap[key, default: JournalDay(date: g.date, dayKey: key)].gratitudeEntries.append(g)
        }
        for i in intentions {
            let key = AppDateFormatters.dayKey(for: i.date)
            dayMap[key, default: JournalDay(date: i.date, dayKey: key)].intentions.append(i)
        }
        for r in reflections {
            let key = AppDateFormatters.dayKey(for: r.date)
            dayMap[key, default: JournalDay(date: r.date, dayKey: key)].reflection = r
        }
        for c in completions {
            let key = AppDateFormatters.dayKey(for: c.date)
            dayMap[key, default: JournalDay(date: c.date, dayKey: key)].completed = true
        }

        return dayMap.values.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise, withBlobs: false)

            if groupedDays.isEmpty {
                VStack(spacing: AppTheme.spacingLg) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("Your journal is empty")
                        .font(AppTheme.title3)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("Complete your first morning session to start your journal")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(AppTheme.spacingXxl)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacingMd) {
                        ForEach(groupedDays, id: \.dayKey) { day in
                            JournalDayCard(day: day)
                        }
                    }
                    .padding(AppTheme.spacingXl)
                }
            }
        }
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct JournalDay {
    let date: Date
    let dayKey: String
    var affirmations: [Affirmation] = []
    var gratitudeEntries: [GratitudeEntry] = []
    var intentions: [DailyIntention] = []
    var reflection: EveningReflection?
    var completed: Bool = false
}
