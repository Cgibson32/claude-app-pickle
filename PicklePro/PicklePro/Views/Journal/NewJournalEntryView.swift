import SwiftUI

struct NewJournalEntryView: View {
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PickleProColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Progress
                        PPProgressBar(progress: Double(viewModel.currentStep) / 6.0)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)

                        // Steps
                        Group {
                            switch viewModel.currentStep {
                            case 0: journalMoodStep
                            case 1: journalPlayTypeStep
                            case 2: journalWentWellStep
                            case 3: journalPatienceStep
                            case 4: journalCommunicationStep
                            case 5: journalEmotionsStep
                            case 6: journalSummaryStep
                            default: EmptyView()
                            }
                        }
                        .padding(.horizontal, 24)

                        // Navigation
                        HStack(spacing: 12) {
                            if viewModel.currentStep > 0 {
                                PPButton(title: "Back", style: .outline) {
                                    viewModel.previousStep()
                                }
                            }

                            if viewModel.currentStep < viewModel.totalSteps - 1 {
                                PPButton(title: "Next", style: .primary) {
                                    viewModel.nextStep()
                                }
                            } else {
                                PPButton(title: "Save Entry", style: .teal) {
                                    viewModel.saveEntry()
                                    dismiss()
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(PickleProColors.textSecondary)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Steps

    private var journalMoodStep: some View {
        VStack(spacing: 20) {
            Text("How are you feeling?")
                .font(PickleProTypography.title2)
                .foregroundColor(.white)

            Text("Select your mood after today's session")
                .font(PickleProTypography.subheadline)
                .foregroundColor(PickleProColors.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Mood.allCases, id: \.self) { mood in
                    MoodButton(
                        mood: mood,
                        isSelected: viewModel.currentEntry.mood == mood
                    ) {
                        viewModel.currentEntry.mood = mood
                    }
                }
            }

            // Energy Level
            VStack(spacing: 12) {
                Text("Energy Level")
                    .font(PickleProTypography.headline)
                    .foregroundColor(.white)

                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { level in
                        Button(action: { viewModel.currentEntry.energyLevel = level }) {
                            Text("\(level)")
                                .font(PickleProTypography.headline)
                                .foregroundColor(
                                    level <= viewModel.currentEntry.energyLevel
                                        ? .black
                                        : PickleProColors.textSecondary
                                )
                                .frame(width: 44, height: 44)
                                .background(
                                    level <= viewModel.currentEntry.energyLevel
                                        ? PickleProColors.accent
                                        : PickleProColors.cardBackground
                                )
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }

    private var journalPlayTypeStep: some View {
        VStack(spacing: 20) {
            Text("What type of play?")
                .font(PickleProTypography.title2)
                .foregroundColor(.white)

            VStack(spacing: 10) {
                ForEach(PlayType.allCases, id: \.self) { type in
                    PPSelectionChip(
                        title: type.rawValue,
                        isSelected: viewModel.currentEntry.playType == type
                    ) {
                        viewModel.currentEntry.playType = type
                    }
                }
            }

            // Tags
            VStack(spacing: 12) {
                Text("Tag your session")
                    .font(PickleProTypography.headline)
                    .foregroundColor(.white)

                FlowLayout(spacing: 8) {
                    ForEach(JournalTag.allCases, id: \.self) { tag in
                        PPChip(
                            title: tag.rawValue,
                            isSelected: viewModel.currentEntry.tags.contains(tag)
                        ) {
                            if viewModel.currentEntry.tags.contains(tag) {
                                viewModel.currentEntry.tags.removeAll { $0 == tag }
                            } else {
                                viewModel.currentEntry.tags.append(tag)
                            }
                        }
                    }
                }
            }
        }
    }

    private var journalWentWellStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What went well today?")
                .font(PickleProTypography.title2)
                .foregroundColor(.white)

            Text("Celebrate your wins, big and small")
                .font(PickleProTypography.subheadline)
                .foregroundColor(PickleProColors.textSecondary)

            TextEditor(text: $viewModel.currentEntry.whatWentWell)
                .font(PickleProTypography.body)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .padding(14)
                .background(PickleProColors.cardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(PickleProColors.accent.opacity(0.3), lineWidth: 1)
                )

            // Session Rating
            VStack(spacing: 10) {
                Text("Overall Session Rating")
                    .font(PickleProTypography.headline)
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { i in
                        Button(action: { viewModel.currentEntry.overallSessionRating = i }) {
                            Image(systemName: i <= viewModel.currentEntry.overallSessionRating ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundColor(
                                    i <= viewModel.currentEntry.overallSessionRating
                                        ? PickleProColors.gold
                                        : PickleProColors.textTertiary
                                )
                        }
                    }
                }
            }
        }
    }

    private var journalPatienceStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Where did patience break down?")
                .font(PickleProTypography.title2)
                .foregroundColor(.white)

            Text("Honest reflection builds awareness")
                .font(PickleProTypography.subheadline)
                .foregroundColor(PickleProColors.textSecondary)

            TextEditor(text: $viewModel.currentEntry.patienceBreakdown)
                .font(PickleProTypography.body)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100)
                .padding(14)
                .background(PickleProColors.cardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

            Text("What skill needs the most work?")
                .font(PickleProTypography.headline)
                .foregroundColor(.white)

            TextEditor(text: $viewModel.currentEntry.skillNeedingWork)
                .font(PickleProTypography.body)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(14)
                .background(PickleProColors.cardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }

    private var journalCommunicationStep: some View {
        VStack(spacing: 20) {
            Text("How was communication?")
                .font(PickleProTypography.title2)
                .foregroundColor(.white)

            Text("Rate your partner communication")
                .font(PickleProTypography.subheadline)
                .foregroundColor(PickleProColors.textSecondary)

            HStack(spacing: 16) {
                ForEach(1...5, id: \.self) { level in
                    Button(action: { viewModel.currentEntry.communicationRating = level }) {
                        VStack(spacing: 6) {
                            Image(systemName: communicationIcon(for: level))
                                .font(.system(size: 28))
                                .foregroundColor(
                                    level <= viewModel.currentEntry.communicationRating
                                        ? PickleProColors.teal
                                        : PickleProColors.textTertiary
                                )
                            Text("\(level)")
                                .font(PickleProTypography.caption)
                                .foregroundColor(PickleProColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            level <= viewModel.currentEntry.communicationRating
                                ? PickleProColors.teal.opacity(0.15)
                                : PickleProColors.cardBackground
                        )
                        .cornerRadius(10)
                    }
                }
            }
        }
    }

    private var journalEmotionsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How did emotions show up?")
                .font(PickleProTypography.title2)
                .foregroundColor(.white)

            Text("Awareness is the first step to control")
                .font(PickleProTypography.subheadline)
                .foregroundColor(PickleProColors.textSecondary)

            TextEditor(text: $viewModel.currentEntry.emotionsDescription)
                .font(PickleProTypography.body)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100)
                .padding(14)
                .background(PickleProColors.cardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

            Text("What will you improve tomorrow?")
                .font(PickleProTypography.headline)
                .foregroundColor(.white)

            TextEditor(text: $viewModel.currentEntry.improvementGoal)
                .font(PickleProTypography.body)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(14)
                .background(PickleProColors.cardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(PickleProColors.accent.opacity(0.3), lineWidth: 1)
                )
        }
    }

    private var journalSummaryStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(PickleProColors.success)

            Text("Great Reflection!")
                .font(PickleProTypography.title)
                .foregroundColor(.white)

            Text("Every entry builds self-awareness.\nYou're investing in your growth.")
                .font(PickleProTypography.body)
                .foregroundColor(PickleProColors.textSecondary)
                .multilineTextAlignment(.center)

            PPCard {
                VStack(alignment: .leading, spacing: 10) {
                    SummaryRow(label: "Mood", value: viewModel.currentEntry.mood.rawValue)
                    SummaryRow(label: "Session Type", value: viewModel.currentEntry.playType.rawValue)
                    SummaryRow(label: "Rating", value: "\(viewModel.currentEntry.overallSessionRating)/5")
                    if !viewModel.currentEntry.tags.isEmpty {
                        SummaryRow(label: "Tags", value: viewModel.currentEntry.tags.map(\.rawValue).joined(separator: ", "))
                    }
                }
            }
        }
    }

    private func communicationIcon(for level: Int) -> String {
        switch level {
        case 1: return "bubble.left"
        case 2: return "bubble.left.fill"
        case 3: return "bubble.left.and.bubble.right"
        case 4: return "bubble.left.and.bubble.right.fill"
        case 5: return "star.bubble.fill"
        default: return "bubble.left"
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(PickleProTypography.subheadline)
                .foregroundColor(PickleProColors.textSecondary)
            Spacer()
            Text(value)
                .font(PickleProTypography.subheadline)
                .foregroundColor(.white)
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxHeight = max(maxHeight, y + rowHeight)
        }

        return (CGSize(width: maxWidth, height: maxHeight), positions)
    }
}
