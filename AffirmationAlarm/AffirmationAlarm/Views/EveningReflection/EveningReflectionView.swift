import SwiftUI
import SwiftData

struct EveningReflectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMood: Int = 2
    @State private var goodThing: String = ""
    @State private var gratitude: String = ""
    @State private var appeared = false

    private let moods: [(emoji: String, label: String)] = [
        ("😔", "Tough"),
        ("😐", "Okay"),
        ("🙂", "Good"),
        ("😊", "Great"),
        ("🤩", "Amazing")
    ]

    var body: some View {
        ZStack {
            GradientBackground(style: .glow)

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 44))
                            .foregroundColor(AppTheme.gold)

                        Text("Evening Reflection")
                            .font(AppTheme.title2)
                            .foregroundColor(AppTheme.textPrimary)

                        Text("Take a moment to reflect on your day")
                            .font(AppTheme.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, 40)

                    // Mood selector
                    VStack(spacing: 12) {
                        Text("How was your day?")
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.textPrimary)

                        HStack(spacing: 16) {
                            ForEach(0..<moods.count, id: \.self) { index in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        selectedMood = index
                                    }
                                    HapticService.light()
                                } label: {
                                    VStack(spacing: 6) {
                                        Text(moods[index].emoji)
                                            .font(.system(size: selectedMood == index ? 36 : 28))
                                        Text(moods[index].label)
                                            .font(AppTheme.caption2)
                                            .foregroundColor(selectedMood == index ? AppTheme.textPrimary : AppTheme.textTertiary)
                                    }
                                    .scaleEffect(selectedMood == index ? 1.1 : 1.0)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppTheme.cardBackground)
                    )

                    // Good thing
                    VStack(alignment: .leading, spacing: 10) {
                        Text("One good thing today")
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.textPrimary)

                        TextField("Something that made you smile...", text: $goodThing, axis: .vertical)
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(2...4)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.inputBackground)
                            )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppTheme.cardBackground)
                    )

                    // Gratitude
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Grateful for...")
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.textPrimary)

                        TextField("What are you thankful for tonight?", text: $gratitude, axis: .vertical)
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(2...4)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.inputBackground)
                            )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppTheme.cardBackground)
                    )

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            saveReflection()
                            HapticService.medium()
                            dismiss()
                        } label: {
                            Text("Save Reflection")
                                .font(AppTheme.headline)
                                .foregroundColor(AppTheme.accentText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Capsule().fill(AppTheme.buttonBackground))
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Skip Tonight")
                                .font(AppTheme.subheadline)
                                .foregroundColor(AppTheme.textTertiary)
                        }
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }

    private func saveReflection() {
        let reflection = EveningReflection(
            mood: selectedMood,
            goodThing: goodThing.trimmingCharacters(in: .whitespacesAndNewlines),
            gratitude: gratitude.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(reflection)
        try? modelContext.save()
    }
}

#Preview {
    EveningReflectionView()
        .modelContainer(for: [EveningReflection.self], inMemory: true)
}
