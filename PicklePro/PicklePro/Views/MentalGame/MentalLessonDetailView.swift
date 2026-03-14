import SwiftUI

struct MentalLessonDetailView: View {
    let lesson: MentalLesson
    @State private var isSaved = false

    var body: some View {
        ZStack {
            PickleProColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: lesson.category.icon)
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: lesson.category.color))
                            .frame(width: 80, height: 80)
                            .background(Color(hex: lesson.category.color).opacity(0.15))
                            .cornerRadius(20)

                        Text(lesson.title)
                            .font(PickleProTypography.title)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text(lesson.category.rawValue)
                            .font(PickleProTypography.captionBold)
                            .foregroundColor(Color(hex: lesson.category.color))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: lesson.category.color).opacity(0.15))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // Content
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(title: "Lesson")

                        ForEach(lesson.content.components(separatedBy: "\n\n"), id: \.self) { paragraph in
                            Text(paragraph)
                                .font(PickleProTypography.body)
                                .foregroundColor(PickleProColors.textSecondary)
                                .lineSpacing(6)
                        }
                    }

                    // Key Takeaways
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(title: "Key Takeaways")
                        ForEach(lesson.keyTakeaways, id: \.self) { takeaway in
                            BulletRow(
                                text: takeaway,
                                color: Color(hex: lesson.category.color),
                                icon: "lightbulb.fill"
                            )
                        }
                    }

                    // Exercises
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(title: "Practice Exercises")
                        ForEach(lesson.exercises, id: \.self) { exercise in
                            BulletRow(
                                text: exercise,
                                color: PickleProColors.success,
                                icon: "checkmark.circle.fill"
                            )
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
