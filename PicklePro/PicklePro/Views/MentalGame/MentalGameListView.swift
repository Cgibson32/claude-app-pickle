import SwiftUI

struct MentalGameListView: View {
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(MockDataService.mentalLessons) { lesson in
                NavigationLink(destination: MentalLessonDetailView(lesson: lesson)) {
                    MentalLessonCard(lesson: lesson)
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

struct MentalLessonCard: View {
    let lesson: MentalLesson

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: lesson.category.icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: lesson.category.color))
                .frame(width: 50, height: 50)
                .background(Color(hex: lesson.category.color).opacity(0.15))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(PickleProTypography.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(lesson.category.rawValue)
                    .font(PickleProTypography.caption)
                    .foregroundColor(Color(hex: lesson.category.color))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(PickleProColors.textTertiary)
        }
        .padding(16)
        .background(PickleProColors.cardBackground)
        .cornerRadius(14)
    }
}
