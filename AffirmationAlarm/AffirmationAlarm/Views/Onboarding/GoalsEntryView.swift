import SwiftUI

struct GoalsEntryView: View {
    @Binding var freeformGoals: String
    @Binding var selectedCategories: Set<GoalCategory>
    @Binding var affirmationCount: Int
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer()
                    .frame(height: 20)

                VStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.textSecondary)

                    Text("What are your goals?")
                        .font(AppTheme.title2)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Tell us about your dreams and aspirations.\nYour affirmations will be tailored to these.")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Freeform goals text editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Goals")
                        .font(AppTheme.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    TextEditor(text: $freeformGoals)
                        .frame(minHeight: 120)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.inputBackground)
                        )
                        .foregroundColor(AppTheme.textPrimary)
                        .tint(AppTheme.textPrimary)
                }

                // Category chips
                VStack(alignment: .leading, spacing: 12) {
                    Text("Focus Areas")
                        .font(AppTheme.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    FlowLayout(spacing: 8) {
                        ForEach(GoalCategory.allCases) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategories.contains(category)
                            ) {
                                if selectedCategories.contains(category) {
                                    selectedCategories.remove(category)
                                } else {
                                    selectedCategories.insert(category)
                                }
                            }
                        }
                    }
                }

                // Affirmation count
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Affirmations")
                        .font(AppTheme.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    Text("How many affirmations would you like each morning?")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.textTertiary)

                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { count in
                            Button {
                                affirmationCount = count
                            } label: {
                                Text("\(count)")
                                    .font(AppTheme.headline)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(affirmationCount == count
                                                  ? AppTheme.chipSelected
                                                  : AppTheme.strokeLight)
                                    )
                                    .foregroundColor(affirmationCount == count ? AppTheme.chipTextSelected : AppTheme.textPrimary)
                            }
                            .animation(.easeInOut(duration: 0.15), value: affirmationCount == count)
                        }
                    }
                }

                Button(action: onContinue) {
                    Text("Continue")
                        .font(AppTheme.headline)
                        .foregroundColor(AppTheme.accentText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(canContinue ? AppTheme.buttonBackground : AppTheme.buttonDisabled)
                        )
                }
                .disabled(!canContinue)
                .padding(.horizontal, 20)

                Spacer()
                    .frame(height: 40)
            }
            .padding()
        }
    }

    private var canContinue: Bool {
        !freeformGoals.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !selectedCategories.isEmpty
    }
}

// Simple flow layout for wrapping chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (
            size: CGSize(width: maxX, height: currentY + lineHeight),
            positions: positions
        )
    }
}

#Preview {
    ZStack {
        GradientBackground()
        GoalsEntryView(
            freeformGoals: .constant("I want to be the best basketball player"),
            selectedCategories: .constant([.successCareer]),
            affirmationCount: .constant(3),
            onContinue: {}
        )
    }
}
