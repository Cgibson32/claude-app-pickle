import SwiftUI

struct GoalsEntryView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXxl) {
                Spacer()
                    .frame(height: AppTheme.spacingXl)

                VStack(spacing: AppTheme.spacingLg) {
                    Image(systemName: "target")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.sunsetOrange)

                    Text("What matters to you?")
                        .font(AppTheme.title)
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Pick 1\u{2013}4 focus areas for your affirmations")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                FlowLayout(spacing: AppTheme.spacingSm) {
                    ForEach(GoalCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: viewModel.selectedCategories.contains(category)
                        ) {
                            if viewModel.selectedCategories.contains(category) {
                                viewModel.selectedCategories.remove(category)
                            } else if viewModel.selectedCategories.count < 4 {
                                viewModel.selectedCategories.insert(category)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                    Text("Personal goals (optional)")
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

                // Evening reflection — folded in here so it doesn't need
                // its own full-screen step. Toggle + time picker.
                eveningReflectionSection

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

    private var eveningReflectionSection: some View {
        VStack(spacing: AppTheme.spacingLg) {
            HStack(spacing: AppTheme.spacingMd) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.gold)
                Text("Evening Reflection")
                    .font(AppTheme.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            Text("A quick nightly check-in — your reflections shape tomorrow's affirmations.")
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: $viewModel.eveningReflectionEnabled) {
                Text("Enable evening reminders")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .tint(AppTheme.sunsetOrange)

            if viewModel.eveningReflectionEnabled {
                DatePicker(
                    "Reminder time",
                    selection: Binding(
                        get: {
                            Calendar.current.date(
                                from: DateComponents(hour: viewModel.eveningReflectionHour, minute: viewModel.eveningReflectionMinute)
                            ) ?? Date()
                        },
                        set: { date in
                            viewModel.eveningReflectionHour = Calendar.current.component(.hour, from: date)
                            viewModel.eveningReflectionMinute = Calendar.current.component(.minute, from: date)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 120)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(AppTheme.spacingXl)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .animation(AppTheme.bouncy, value: viewModel.eveningReflectionEnabled)
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
