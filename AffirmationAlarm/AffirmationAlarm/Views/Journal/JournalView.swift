import SwiftUI
import SwiftData

struct JournalDay: Identifiable {
    let id: Date
    let affirmations: [Affirmation]
    let gratitude: GratitudeEntry?
    let intention: DailyIntention?
    let eveningReflection: EveningReflection?
    let completedSequence: Bool
}

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var journalDays: [JournalDay] = []

    var body: some View {
        ZStack {
            GradientBackground(style: .glow)

            if journalDays.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 44))
                        .foregroundColor(AppTheme.textTertiary)
                    Text("Your journal is empty")
                        .font(AppTheme.title3)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("Complete your first affirmation sequence\nto start building your journal.")
                        .font(AppTheme.subheadline)
                        .foregroundColor(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(journalDays) { day in
                            JournalDayCard(day: day)
                        }
                    }
                    .padding()
                    .padding(.top, 10)
                }
            }
        }
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            loadJournalDays()
        }
    }

    private func loadJournalDays() {
        let calendar = Calendar.current

        // Fetch all data
        let affirmations = (try? modelContext.fetch(FetchDescriptor<Affirmation>(
            sortBy: [SortDescriptor(\Affirmation.generatedFor, order: .reverse)]
        ))) ?? []

        let gratitudeEntries = (try? modelContext.fetch(FetchDescriptor<GratitudeEntry>(
            sortBy: [SortDescriptor(\GratitudeEntry.date, order: .reverse)]
        ))) ?? []

        let intentions = (try? modelContext.fetch(FetchDescriptor<DailyIntention>(
            sortBy: [SortDescriptor(\DailyIntention.date, order: .reverse)]
        ))) ?? []

        let reflections = (try? modelContext.fetch(FetchDescriptor<EveningReflection>(
            sortBy: [SortDescriptor(\EveningReflection.date, order: .reverse)]
        ))) ?? []

        let completions = (try? modelContext.fetch(FetchDescriptor<SequenceCompletion>(
            sortBy: [SortDescriptor(\SequenceCompletion.date, order: .reverse)]
        ))) ?? []

        // Collect all unique dates
        var allDates = Set<Date>()
        for a in affirmations { allDates.insert(calendar.startOfDay(for: a.generatedFor)) }
        for g in gratitudeEntries { allDates.insert(calendar.startOfDay(for: g.date)) }
        for i in intentions { allDates.insert(calendar.startOfDay(for: i.date)) }
        for r in reflections { allDates.insert(calendar.startOfDay(for: r.date)) }
        for c in completions { allDates.insert(calendar.startOfDay(for: c.date)) }

        // Build journal days
        journalDays = allDates.sorted(by: >).map { date in
            JournalDay(
                id: date,
                affirmations: affirmations.filter { calendar.isDate($0.generatedFor, inSameDayAs: date) },
                gratitude: gratitudeEntries.first { calendar.isDate($0.date, inSameDayAs: date) },
                intention: intentions.first { calendar.isDate($0.date, inSameDayAs: date) },
                eveningReflection: reflections.first { calendar.isDate($0.date, inSameDayAs: date) },
                completedSequence: completions.contains { calendar.isDate($0.date, inSameDayAs: date) }
            )
        }
    }
}

#Preview {
    NavigationStack {
        JournalView()
    }
    .modelContainer(for: [Affirmation.self, GratitudeEntry.self, DailyIntention.self, EveningReflection.self, SequenceCompletion.self], inMemory: true)
}
