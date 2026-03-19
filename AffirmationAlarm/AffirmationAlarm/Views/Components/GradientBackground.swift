import SwiftUI

struct GradientBackground: View {
    var style: GradientStyle = .sunrise

    enum GradientStyle {
        case sunrise
        case energy
        case glow

        var colors: [Color] {
            switch self {
            case .sunrise:
                // Charcoal blue → deep plum → burnt amber
                return [
                    AppTheme.charcoalBlue,
                    AppTheme.deepPlum,
                    AppTheme.burntAmber
                ]
            case .energy:
                // Charcoal blue → dark amber → amber gold
                return [
                    AppTheme.charcoalBlue,
                    AppTheme.darkAmber,
                    AppTheme.amberGold
                ]
            case .glow:
                // Deep plum → deep rust → coral rose
                return [
                    AppTheme.deepPlum,
                    AppTheme.deepRust,
                    AppTheme.coralRose
                ]
            }
        }
    }

    var body: some View {
        LinearGradient(
            colors: style.colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    GradientBackground()
}
