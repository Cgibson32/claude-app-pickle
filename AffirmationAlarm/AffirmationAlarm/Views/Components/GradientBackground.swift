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
                return [
                    Color(red: 1.0, green: 0.7, blue: 0.4),
                    Color(red: 1.0, green: 0.5, blue: 0.5),
                    Color(red: 0.6, green: 0.3, blue: 0.7)
                ]
            case .warmEvening:
                return [
                    Color(red: 0.95, green: 0.6, blue: 0.4),
                    Color(red: 0.85, green: 0.4, blue: 0.5),
                    Color(red: 0.5, green: 0.25, blue: 0.6)
                ]
            case .calm:
                return [
                    Color(red: 0.4, green: 0.5, blue: 0.8),
                    Color(red: 0.5, green: 0.4, blue: 0.7),
                    Color(red: 0.3, green: 0.3, blue: 0.5)
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
