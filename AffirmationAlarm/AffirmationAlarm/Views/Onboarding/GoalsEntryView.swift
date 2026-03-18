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
                        .foregroundColor(.white.opacity(0.9))

                    Text("What are your goals?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Tell us about your dreams and aspirations.\nYour affirmations will be tailored to these.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                // Freeform goals text editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Goals")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))

                    TextEditor(text: $freeformGoals)
                        .frame(minHeight: 120)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.2))
                        )
                        .foregroundColor(.white)
                        .tint(.white)
                }

                // Category chips
                VStack(alignment: .leading, spacing: 12) {
                    Text("Focus Areas")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))

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
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))

                    Text("How many affirmations would you like each morning?")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { count in
                            Button {
                                affirmationCount = count
                            } label: {
                                Text("\(count)")
                                    .font(.headline)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(affirmationCount == count
                                                  ? Color.white
                                                  : Color.white.opacity(0.2))
                                    )
                                    .foregroundColor(affirmationCount == count ? .black : .white)
                            }
                            .animation(.easeInOut(duration: 0.15), value: affirmationCount == count)
                        }
                    }
                }

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(canContinue ? .white : .white.opacity(0.4))
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
