import SwiftUI

/// A 4:5 portrait card optimized for sharing to Instagram, iMessage, and
/// other social surfaces. Designed at 540×675 points and rendered at
/// scale 2 by `AffirmationImageRenderer` for a final 1080×1350 pixel
/// image — the canonical Instagram feed ratio.
///
/// The visual hierarchy is: small sunrise glyph at top, the affirmation
/// as the hero in Sora-Bold, a thin gold rule, and a tracked brand mark
/// at the bottom. Background is a vertical sunrise gradient (warm gold
/// fading to deep plum) with a soft radial glow centered behind the
/// text so longer affirmations stay legible.
struct ShareableAffirmationCard: View {
    let text: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.gold.opacity(0.55),
                    AppTheme.sunsetOrange.opacity(0.75),
                    AppTheme.sunsetDeepRed,
                    AppTheme.deepPlum,
                    AppTheme.charcoalBlue
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [AppTheme.gold.opacity(0.22), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 280
            )

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(AppTheme.gold)
                    .padding(.bottom, 40)

                Text(text)
                    .font(.custom("Sora-Bold", size: 30))
                    .foregroundStyle(AppTheme.warmWhite)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 52)

                Rectangle()
                    .fill(AppTheme.gold.opacity(0.65))
                    .frame(width: 48, height: 1.5)
                    .padding(.top, 36)

                Spacer()

                HStack(spacing: 7) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.gold.opacity(0.85))
                    Text("AFFIRMATION ALARM")
                        .font(.custom("DMSans-Medium", size: 11))
                        .tracking(2.6)
                        .foregroundStyle(AppTheme.warmWhite.opacity(0.7))
                }
                .padding(.bottom, 40)
            }
        }
        .frame(width: 540, height: 675)
    }
}

#Preview {
    ShareableAffirmationCard(
        text: "You were built to read the room before anyone else, and that quiet awareness is your edge."
    )
}
