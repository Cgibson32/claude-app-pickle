import SwiftUI

struct JournalView: View {
    @StateObject private var viewModel = JournalViewModel()
    @State private var showNewEntry = false

    var body: some View {
        NavigationStack {
            ZStack {
                PickleProColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // New Entry Button
                        PPButton(title: "New Journal Entry", style: .primary) {
                            showNewEntry = true
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        // Entries List
                        if viewModel.entries.isEmpty {
                            EmptyJournalView()
                                .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.entries) { entry in
                                    JournalEntryCard(entry: entry)
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showNewEntry) {
                NewJournalEntryView(viewModel: viewModel)
            }
        }
    }
}

struct EmptyJournalView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 50))
                .foregroundColor(PickleProColors.textTertiary)

            Text("No entries yet")
                .font(PickleProTypography.title3)
                .foregroundColor(.white)

            Text("Start journaling after your next session.\nEvery reflection is a step toward mastery.")
                .font(PickleProTypography.subheadline)
                .foregroundColor(PickleProColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct JournalEntryCard: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: entry.mood.icon)
                    .foregroundColor(PickleProColors.accent)

                Text(entry.mood.rawValue)
                    .font(PickleProTypography.headline)
                    .foregroundColor(.white)

                Spacer()

                Text(entry.date, style: .date)
                    .font(PickleProTypography.caption)
                    .foregroundColor(PickleProColors.textTertiary)
            }

            if !entry.whatWentWell.isEmpty {
                Text(entry.whatWentWell)
                    .font(PickleProTypography.callout)
                    .foregroundColor(PickleProColors.textSecondary)
                    .lineLimit(2)
            }

            HStack(spacing: 6) {
                Text(entry.playType.rawValue)
                    .font(PickleProTypography.caption)
                    .foregroundColor(PickleProColors.teal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(PickleProColors.teal.opacity(0.15))
                    .cornerRadius(6)

                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= entry.overallSessionRating ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(
                                i <= entry.overallSessionRating
                                    ? PickleProColors.gold
                                    : PickleProColors.textTertiary
                            )
                    }
                }

                Spacer()

                if !entry.tags.isEmpty {
                    Text("+\(entry.tags.count) tags")
                        .font(PickleProTypography.caption)
                        .foregroundColor(PickleProColors.textTertiary)
                }
            }
        }
        .padding(16)
        .background(PickleProColors.cardBackground)
        .cornerRadius(14)
    }
}
