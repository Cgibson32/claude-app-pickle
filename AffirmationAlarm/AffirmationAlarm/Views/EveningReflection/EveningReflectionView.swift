import SwiftUI
import SwiftData

struct EveningReflectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMood = 2
    @State private var goodThing = ""
    @State private var gratitude = ""
    @State private var emojiAnimated = false

    private var moods: [(emoji: String, label: String)] {
        zip(AppConstants.moodEmojis, AppConstants.moodLabels).map { ($0, $1) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground(style: .glow)

                ScrollView {
                    VStack(spacing: AppTheme.spacingXxl) {
                        VStack(spacing: AppTheme.spacingLg) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(AppTheme.gold)

                            Text("Evening Reflection")
                                .font(AppTheme.title2)
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        // Mood selector with bouncy emojis
                        VStack(spacing: AppTheme.spacingMd) {
                            Text("How was your day?")
                                .font(AppTheme.headline)
                                .foregroundStyle(AppTheme.textSecondary)

                            HStack(spacing: AppTheme.spacingLg) {
                                ForEach(0..<moods.count, id: \.self) { index in
                                    Button {
                                        HapticService.selection()
                                        withAnimation(AppTheme.bouncy) {
                                            selectedMood = index
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(moods[index].emoji)
                                                .font(.system(size: selectedMood == index ? 40 : 28))
                                                .scaleEffect(emojiAnimated ? 1.0 : 0.3)
                                                .animation(
                                                    AppTheme.bouncy.delay(Double(index) * 0.08),
                                                    value: emojiAnimated
                                                )
                                            Text(moods[index].label)
                                                .font(AppTheme.caption2)
                                                .foregroundStyle(selectedMood == index ? AppTheme.gold : AppTheme.textTertiary)
                                        }
                                    }
                                    .buttonStyle(.bounce)
                                    .accessibilityLabel("\(moods[index].label) mood")
                                }
                            }
                        }

                        // Good thing
                        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                            Text("One good thing today")
                                .font(AppTheme.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)

                            TextField("What went well?", text: $goodThing, axis: .vertical)
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(3...6)
                                .padding(AppTheme.spacingLg)
                                .background(AppTheme.inputBackground)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                        }

                        // Gratitude
                        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                            Text("I'm grateful for...")
                                .font(AppTheme.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)

                            TextField("What are you thankful for?", text: $gratitude, axis: .vertical)
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(3...6)
                                .padding(AppTheme.spacingLg)
                                .background(AppTheme.inputBackground)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                        }

                        Button("Save Reflection") {
                            save()
                        }
                        .buttonStyle(PillButtonStyle())

                        Button("Skip Tonight") {
                            dismiss()
                        }
                        .font(AppTheme.subheadline)
                        .foregroundStyle(AppTheme.textTertiary)
                    }
                    .padding(AppTheme.spacingXl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }
            .onAppear {
                emojiAnimated = true
            }
        }
    }

    private func save() {
        let reflection = EveningReflection(
            mood: selectedMood,
            goodThing: goodThing.trimmingCharacters(in: .whitespaces),
            gratitude: gratitude.trimmingCharacters(in: .whitespaces)
        )
        modelContext.insert(reflection)
        try? modelContext.save()

        HapticService.success()
        dismiss()
    }
}
