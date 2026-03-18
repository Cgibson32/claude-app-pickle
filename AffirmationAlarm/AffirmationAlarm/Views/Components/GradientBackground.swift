import SwiftUI

struct GradientBackground: View {
    var style: GradientStyle = .sunrise

    enum GradientStyle {
        case sunrise
        case warmEvening
        case calm

        var colors: [Color] {
            switch self {
            case .sunrise:
                // Deep forest green → warm brown-green
                return [
                    AppTheme.deepGreen,
                    Color(hex: "2E5D2A"),
                    AppTheme.darkBrown
                ]
            case .warmEvening:
                // Rich brown → deep green
                return [
                    AppTheme.darkBrown,
                    Color(hex: "4E342E"),
                    AppTheme.deepGreen
                ]
            case .calm:
                // Muted green → dark brown with warm undertone
                return [
                    Color(hex: "1B4332"),
                    Color(hex: "3E5243"),
                    Color(hex: "4E342E")
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
