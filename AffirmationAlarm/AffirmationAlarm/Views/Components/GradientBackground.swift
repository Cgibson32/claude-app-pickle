import SwiftUI

enum GradientStyle {
    case sunrise
    case energy
    case glow

    var baseColor: Color {
        AppTheme.charcoalBlue
    }

    var glowColor: Color {
        switch self {
        case .sunrise: return AppTheme.warmAmber
        case .energy: return AppTheme.gold
        case .glow: return AppTheme.sunsetOrange
        }
    }

    var glowOpacity: Double {
        switch self {
        case .sunrise: return 0.07
        case .energy: return 0.10
        case .glow: return 0.08
        }
    }
}

struct GradientBackground: View {
    var style: GradientStyle = .sunrise
    var withBlobs: Bool = true

    var body: some View {
        ZStack {
            style.baseColor

            if withBlobs {
                RadialGradient(
                    colors: [
                        style.glowColor.opacity(style.glowOpacity),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 600
                )
            }
        }
        .ignoresSafeArea()
    }
}

struct BlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.4),
            control1: CGPoint(x: w * 0.8, y: h * 0.0),
            control2: CGPoint(x: w * 1.1, y: h * 0.2)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.6, y: h),
            control1: CGPoint(x: w * 0.95, y: h * 0.7),
            control2: CGPoint(x: w * 0.8, y: h * 0.95)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: h * 0.6),
            control1: CGPoint(x: w * 0.3, y: h * 1.05),
            control2: CGPoint(x: -w * 0.1, y: h * 0.8)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control1: CGPoint(x: w * 0.05, y: h * 0.3),
            control2: CGPoint(x: w * 0.2, y: h * 0.05)
        )
        return path
    }
}
