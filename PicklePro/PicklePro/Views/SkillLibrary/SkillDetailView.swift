import SwiftUI

struct SkillDetailView: View {
    let skill: Skill
    @State private var isSaved = false

    var body: some View {
        ZStack {
            PickleProColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: skill.icon)
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: skill.category.color))
                            .frame(width: 80, height: 80)
                            .background(Color(hex: skill.category.color).opacity(0.15))
                            .cornerRadius(20)

                        Text(skill.title)
                            .font(PickleProTypography.title)
                            .foregroundColor(.white)

                        Text(skill.category.rawValue)
                            .font(PickleProTypography.captionBold)
                            .foregroundColor(Color(hex: skill.category.color))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: skill.category.color).opacity(0.15))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // Explanation
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(title: "Overview")
                        Text(skill.explanation)
                            .font(PickleProTypography.body)
                            .foregroundColor(PickleProColors.textSecondary)
                            .lineSpacing(6)
                    }

                    // Mental Cues
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(title: "Mental Cues")
                        ForEach(skill.mentalCues, id: \.self) { cue in
                            PPQuoteCard(quote: cue)
                        }
                    }

                    // Coaching Tips
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(title: "Coaching Tips")
                        ForEach(skill.coachingTips, id: \.self) { tip in
                            BulletRow(text: tip, color: Color(hex: skill.category.color))
                        }
                    }

                    // Common Mistakes
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(title: "Common Mistakes")
                        ForEach(skill.commonMistakes, id: \.self) { mistake in
                            BulletRow(text: mistake, color: PickleProColors.error, icon: "xmark.circle.fill")
                        }
                    }

                    // Practice Ideas
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(title: "Practice Ideas")
                        ForEach(skill.practiceIdeas, id: \.self) { idea in
                            BulletRow(text: idea, color: PickleProColors.success, icon: "checkmark.circle.fill")
                        }
                    }

                    // Save Button
                    PPButton(
                        title: isSaved ? "Saved" : "Save Lesson",
                        style: isSaved ? .secondary : .primary
                    ) {
                        withAnimation { isSaved.toggle() }
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(PickleProTypography.title3)
            .foregroundColor(.white)
    }
}

struct BulletRow: View {
    let text: String
    var color: Color = PickleProColors.accent
    var icon: String = "circle.fill"

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: icon == "circle.fill" ? 6 : 14))
                .foregroundColor(color)
                .frame(width: 14)
                .padding(.top, icon == "circle.fill" ? 8 : 2)

            Text(text)
                .font(PickleProTypography.callout)
                .foregroundColor(PickleProColors.textSecondary)
                .lineSpacing(4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PickleProColors.cardBackground)
        .cornerRadius(12)
    }
}
