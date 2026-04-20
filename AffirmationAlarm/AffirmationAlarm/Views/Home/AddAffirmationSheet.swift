import SwiftUI
import SwiftData

/// Sheet for composing a custom affirmation. Extracted from `HomeView`
/// so the home screen shows *output* (your affirmations) rather than
/// mixing a persistent input surface inline. Stored as a priority
/// favorite + custom row so the new line is guaranteed to play on the
/// next alarm fire.
struct AddAffirmationSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @FocusState private var focused: Bool

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground(style: .sunrise, withBlobs: false)

                VStack(alignment: .leading, spacing: AppTheme.spacingLg) {
                    Text("Write something you need to hear tomorrow morning. It'll play alongside your generated affirmations.")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    TextField(
                        "Your affirmation…",
                        text: $text,
                        axis: .vertical
                    )
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(3...10)
                    .padding(AppTheme.spacingLg)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    .focused($focused)

                    Spacer()
                }
                .padding(AppTheme.spacingXl)
            }
            .navigationTitle("New Affirmation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .foregroundStyle(trimmed.isEmpty ? AppTheme.textTertiary : AppTheme.gold)
                        .fontWeight(.semibold)
                        .disabled(trimmed.isEmpty)
                }
            }
            .onAppear { focused = true }
        }
    }

    private func save() {
        guard !trimmed.isEmpty else { return }
        let affirmation = Affirmation(text: trimmed, generatedFor: Date())
        affirmation.favoriteType = 1
        affirmation.isFavorited = true
        affirmation.isCustom = true
        modelContext.insert(affirmation)
        HapticService.success()
        dismiss()
    }
}
