import SwiftUI

struct PPProgressBar: View {
    let progress: Double
    var height: CGFloat = 6
    var color: Color = PickleProColors.accent

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(PickleProColors.surfaceLight)
                    .frame(height: height)

                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * min(max(progress, 0), 1), height: height)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: height)
    }
}

struct PPStreakBadge: View {
    let count: Int
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(PickleProTypography.title)
                .foregroundColor(PickleProColors.accent)

            Text(label)
                .font(PickleProTypography.caption)
                .foregroundColor(PickleProColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(PickleProColors.cardBackground)
        .cornerRadius(14)
    }
}
