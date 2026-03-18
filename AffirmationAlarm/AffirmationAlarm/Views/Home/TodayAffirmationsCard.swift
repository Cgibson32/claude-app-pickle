import SwiftUI
import SwiftData

struct TodayAffirmationsCard: View {
    let affirmations: [Affirmation]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(AppTheme.textSecondary)
                Text("Today's Affirmations")
                    .font(AppTheme.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
            }

            if affirmations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.textTertiary)
                    Text("Your affirmations will appear\nhere after your first alarm.")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(affirmations) { affirmation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.textTertiary)
                                .padding(.top, 2)

                            Text(affirmation.text)
                                .font(AppTheme.subheadline)
                                .foregroundColor(AppTheme.textPrimary)

                            Spacer()

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    affirmation.isFavorited.toggle()
                                }
                            } label: {
                                Image(systemName: affirmation.isFavorited ? "heart.fill" : "heart")
                                    .font(.system(size: 17))
                                    .foregroundColor(affirmation.isFavorited ? AppTheme.favorite : AppTheme.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
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
