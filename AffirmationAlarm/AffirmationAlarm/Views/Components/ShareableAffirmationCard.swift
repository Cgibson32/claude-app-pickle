import SwiftUI

/// Square 1080×1080 share card. Designed to feel like a quiet, refined
/// printed page: warm radial glow on near-black, cream serif body, and a
/// subtle italic-gold accent on the trailing clause (Resonance-style).
struct ShareableAffirmationCard: View {
    let text: String

    static let canvasSize: CGFloat = 1080

    private let obsidianCenter = Color(red: 0.16, green: 0.12, blue: 0.07)
    private let obsidianMid    = Color(red: 0.05, green: 0.04, blue: 0.03)
    private let obsidianEdge   = Color(red: 0.02, green: 0.02, blue: 0.02)
    private let cream          = Color(red: 0.96, green: 0.93, blue: 0.86)
    private let mutedGold      = Color(red: 0.79, green: 0.66, blue: 0.42)

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [obsidianCenter, obsidianMid, obsidianEdge],
                center: .center,
                startRadius: 0,
                endRadius: Self.canvasSize * 0.72
            )

            VStack(spacing: 0) {
                Spacer().frame(height: 110)

                Text("TODAY'S AFFIRMATION")
                    .font(.system(size: 22, weight: .medium))
                    .tracking(7)
                    .foregroundStyle(mutedGold)

                Spacer(minLength: 0)

                styledAffirmation
                    .font(.system(size: 62, weight: .regular, design: .serif))
                    .multilineTextAlignment(.center)
                    .lineSpacing(14)
                    .padding(.horizontal, 96)

                Spacer(minLength: 0)

                Rectangle()
                    .fill(mutedGold.opacity(0.55))
                    .frame(width: 56, height: 1)

                Spacer().frame(height: 36)

                Text("AFFIRMATION ALARM")
                    .font(.system(size: 18, weight: .medium))
                    .tracking(8)
                    .foregroundStyle(cream.opacity(0.55))

                Spacer().frame(height: 96)
            }
        }
        .frame(width: Self.canvasSize, height: Self.canvasSize)
    }

    /// Resonance-style typographic accent: when the affirmation has a
    /// trailing clause (anything after the last comma), render it italic
    /// gold. Otherwise the whole line is upright cream.
    private var styledAffirmation: Text {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let commaIdx = trimmed.lastIndex(of: ","),
              trimmed.distance(from: trimmed.startIndex, to: commaIdx) >= 8 else {
            return Text(trimmed).foregroundColor(cream)
        }

        var head = AttributedString(String(trimmed[..<commaIdx]) + ", ")
        head.foregroundColor = cream

        var tail = AttributedString(
            String(trimmed[trimmed.index(after: commaIdx)...])
                .trimmingCharacters(in: .whitespaces)
        )
        tail.foregroundColor = mutedGold
        tail.inlinePresentationIntent = .emphasized

        return Text(head + tail)
    }
}
