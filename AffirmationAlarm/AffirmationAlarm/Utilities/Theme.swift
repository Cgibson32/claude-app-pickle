import SwiftUI

struct AppTheme {
    // MARK: - Brand Colors
    static let charcoalBlue = Color(hex: "1A1A2E")
    static let sunsetOrange = Color(hex: "FF8C42")
    static let gold = Color(hex: "FFD166")
    static let warmAmber = Color(hex: "F4A261")
    static let warmWhite = Color(hex: "FFF5EB")

    // MARK: - Dark Gradient Colors
    static let deepPlum = Color(hex: "2D1B4E")
    static let burntAmber = Color(hex: "7C3A1C")
    static let darkAmber = Color(hex: "4A2600")
    static let deepRust = Color(hex: "9A4012")

    // MARK: - Semantic Text Colors
    static let textPrimary = warmWhite
    static let textSecondary = warmWhite.opacity(0.7)
    static let textTertiary = warmWhite.opacity(0.5)

    // MARK: - UI Element Colors
    static let cardBackground = Color.white.opacity(0.1)
    static let cardBackgroundHover = Color.white.opacity(0.15)
    static let inputBackground = Color.white.opacity(0.12)
    static let strokeLight = Color.white.opacity(0.15)

    // MARK: - Spacing
    static let spacingSm: CGFloat = 8
    static let spacingMd: CGFloat = 12
    static let spacingLg: CGFloat = 16
    static let spacingXl: CGFloat = 20
    static let spacingXxl: CGFloat = 24
    static let spacing3xl: CGFloat = 32

    // MARK: - Corner Radius (softer, more playful)
    static let radiusSm: CGFloat = 12
    static let radiusMd: CGFloat = 16
    static let radiusLg: CGFloat = 24
    static let radiusXl: CGFloat = 32
    static let radiusPill: CGFloat = 100

    // MARK: - Animations
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let gentle = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let quick = Animation.spring(response: 0.3, dampingFraction: 0.8)

    // MARK: - Fonts
    static func soraFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold: return .custom("Sora-Bold", size: size)
        case .semibold: return .custom("Sora-SemiBold", size: size)
        case .medium: return .custom("Sora-Medium", size: size)
        default: return .custom("Sora-Regular", size: size)
        }
    }

    static func dmSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold: return .custom("DMSans-Bold", size: size)
        case .semibold: return .custom("DMSans-SemiBold", size: size)
        case .medium: return .custom("DMSans-Medium", size: size)
        case .light: return .custom("DMSans-Light", size: size)
        default: return .custom("DMSans-Regular", size: size)
        }
    }

    // MARK: - Semantic Fonts
    static let largeTitle = soraFont(34, weight: .bold)
    static let title = soraFont(28, weight: .bold)
    static let title2 = soraFont(22, weight: .semibold)
    static let title3 = soraFont(20, weight: .medium)
    static let headline = dmSans(17, weight: .semibold)
    static let bodyFont = dmSans(17)
    static let subheadline = dmSans(15, weight: .medium)
    static let caption = dmSans(12)
    static let caption2 = dmSans(11)
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Playful Button Style

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppTheme.quick, value: configuration.isPressed)
    }
}

struct PillButtonStyle: ButtonStyle {
    var background: Color = AppTheme.sunsetOrange
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.headline)
            .foregroundStyle(foreground)
            .padding(.horizontal, AppTheme.spacingXxl)
            .padding(.vertical, AppTheme.spacingLg)
            .background(background)
            .clipShape(Capsule())
            .shadow(color: background.opacity(0.4), radius: 12, y: 6)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AppTheme.quick, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BounceButtonStyle {
    static var bounce: BounceButtonStyle { BounceButtonStyle() }
}
