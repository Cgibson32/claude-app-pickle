import SwiftUI

enum GradientStyle {
    case sunrise
    case energy
    case glow

    var colors: [Color] {
        switch self {
        case .sunrise: return [AppTheme.charcoalBlue, AppTheme.deepPlum, AppTheme.burntAmber]
        case .energy: return [AppTheme.charcoalBlue, AppTheme.darkAmber, AppTheme.gold]
        case .glow: return [AppTheme.deepPlum, AppTheme.deepRust, AppTheme.warmAmber]
        }
    }
}

struct GradientBackground: View {
    var style: GradientStyle = .sunrise
    var withBlobs: Bool = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: style.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if withBlobs {
                BlobShape()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 300, height: 300)
                    .offset(x: 120, y: -200)
                    .blur(radius: 40)

                BlobShape()
                    .fill(AppTheme.sunsetOrange.opacity(0.08))
                    .frame(width: 250, height: 250)
                    .offset(x: -100, y: 300)
                    .blur(radius: 50)
                    .rotationEffect(.degrees(180))
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
