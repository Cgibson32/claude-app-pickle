import SwiftUI

struct PostPlayReflectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var mood: Mood = .focused
    @State private var sessionRating: Int = 3
    @State private var whatWentWell: String = ""
    @State private var toImprove: String = ""
    @State private var currentStep = 0

    var body: some View {
        NavigationStack {
            ZStack {
                PickleProColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 40))
                                .foregroundColor(PickleProColors.teal)

                            Text("Post-Play Reflection")
                                .font(PickleProTypography.title)
                                .foregroundColor(.white)

                            Text("Take a moment to reflect and grow")
                                .font(PickleProTypography.subheadline)
                                .foregroundColor(PickleProColors.textSecondary)
                        }
                        .padding(.top, 20)

                        // Mood Check
                        VStack(alignment: .leading, spacing: 14) {
                            Text("How do you feel?")
                                .font(PickleProTypography.headline)
                                .foregroundColor(.white)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 10) {
                                ForEach(Mood.allCases, id: \.self) { m in
                                    MoodButton(mood: m, isSelected: mood == m) {
                                        mood = m
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Session Rating
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Rate your session")
                                .font(PickleProTypography.headline)
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { i in
                                    Button(action: { sessionRating = i }) {
                                        Image(systemName: i <= sessionRating ? "star.fill" : "star")
                                            .font(.system(size: 28))
                                            .foregroundColor(
                                                i <= sessionRating
                                                    ? PickleProColors.gold
                                                    : PickleProColors.textTertiary
                                            )
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 24)

                        // What Went Well
                        VStack(alignment: .leading, spacing: 10) {
                            Text("What went well today?")
                                .font(PickleProTypography.headline)
                                .foregroundColor(.white)

                            TextEditor(text: $whatWentWell)
                                .font(PickleProTypography.body)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 80)
                                .padding(12)
                                .background(PickleProColors.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 24)

                        // To Improve
                        VStack(alignment: .leading, spacing: 10) {
                            Text("What will you work on next?")
                                .font(PickleProTypography.headline)
                                .foregroundColor(.white)

                            TextEditor(text: $toImprove)
                                .font(PickleProTypography.body)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 80)
                                .padding(12)
                                .background(PickleProColors.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 24)

                        // Submit
                        PPButton(title: "Save Reflection", style: .teal) {
                            dismiss()
                        }
                        .padding(.horizontal, 24)

                        PPQuoteCard(quote: "Every reflection is a step toward mastery.")
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(PickleProColors.accent)
                }
            }
        }
    }
}

struct MoodButton: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: mood.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? PickleProColors.accent : PickleProColors.textSecondary)

                Text(mood.rawValue)
                    .font(PickleProTypography.caption)
                    .foregroundColor(isSelected ? .white : PickleProColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ? PickleProColors.accent.opacity(0.15) : PickleProColors.cardBackground
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? PickleProColors.accent.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
