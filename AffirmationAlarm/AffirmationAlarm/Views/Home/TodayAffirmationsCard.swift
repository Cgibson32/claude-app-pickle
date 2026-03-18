import SwiftUI
import SwiftData

struct TodayAffirmationsCard: View {
    let affirmations: [Affirmation]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.white.opacity(0.7))
                Text("Today's Affirmations")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }

            if affirmations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "text.quote")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.4))
                    Text("Your affirmations will appear\nhere after your first alarm.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(affirmations.prefix(3).enumerated()), id: \.offset) { _, affirmation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "quote.opening")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.top, 2)

                            Text(affirmation.text)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
        )
    }
}

#Preview {
    ZStack {
        GradientBackground()
        TodayAffirmationsCard(affirmations: [])
            .padding()
    }
}
