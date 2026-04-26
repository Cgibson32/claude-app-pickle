import SwiftUI

struct GoalsEntryView: View {
    @Bindable var viewModel: OnboardingViewModel

    /// Six prefilled examples to break the blank-page freeze. Tapping
    /// appends to the goals field rather than replacing — the user can
    /// stack examples or use one as a seed they edit.
    private let exampleGoals = [
        "Become a more present parent",
        "Get my health back on track",
        "Build my business",
        "Finish writing my book",
        "Heal and feel whole again",
        "Learn to love myself"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXxl) {
                Spacer()
                    .frame(height: AppTheme.spacingXl)

                VStack(spacing: AppTheme.spacingLg) {
                    Image(systemName: "target")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.sunsetOrange)

                    Text("What are your goals?")
                        .font(AppTheme.title)
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Your affirmations will be tailored to exactly what you write here.")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                    Text("Need a starting point?")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    FlowLayout(spacing: 8) {
                        ForEach(exampleGoals, id: \.self) { example in
                            Button {
                                HapticService.selection()
                                appendExample(example)
                            } label: {
                                Text(example)
                                    .font(AppTheme.caption)
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .padding(.horizontal, AppTheme.spacingMd)
                                    .padding(.vertical, AppTheme.spacingSm)
                                    .background(AppTheme.cardBackground)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().strokeBorder(AppTheme.gold.opacity(0.20), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.bounce)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                    Text("Your goals")
                        .font(AppTheme.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    TextEditor(text: $viewModel.goals)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(AppTheme.spacingMd)
                        .frame(minHeight: 100)
                        .background(AppTheme.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                }

                if ProfanityFilter.containsProfanity(viewModel.goals) {
                    Text("Please remove inappropriate language from your goals.")
                        .font(AppTheme.caption)
                        .foregroundStyle(.red.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(spacing: AppTheme.spacingSm) {
                    Text("Daily affirmations: \(viewModel.affirmationCount)")
                        .font(AppTheme.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: AppTheme.spacingMd) {
                        ForEach(1...5, id: \.self) { count in
                            Button("\(count)") {
                                HapticService.selection()
                                viewModel.affirmationCount = count
                            }
                            .font(AppTheme.headline)
                            .foregroundStyle(count == viewModel.affirmationCount ? AppTheme.charcoalBlue : AppTheme.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(count == viewModel.affirmationCount ? AppTheme.gold : AppTheme.cardBackground)
                            .clipShape(Circle())
                            .buttonStyle(.bounce)
                        }
                    }
                }

                Button("Continue") {
                    HapticService.medium()
                    viewModel.advance()
                }
                .buttonStyle(PillButtonStyle())
                .disabled(!viewModel.canAdvance)
                .opacity(viewModel.canAdvance ? 1.0 : 0.5)

                Spacer()
                    .frame(height: AppTheme.spacing3xl)
            }
            .padding(.horizontal, AppTheme.spacingXxl)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func appendExample(_ text: String) {
        let current = viewModel.goals.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.goals = current.isEmpty ? text : current + "\n" + text
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: point, anchor: .topLeading, proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
