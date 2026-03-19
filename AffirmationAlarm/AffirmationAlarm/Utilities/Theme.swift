import SwiftUI

// MARK: - Brand Theme

enum AppTheme {

    // MARK: - Brand Colors (Ember & Gold)

    static let charcoalBlue = Color(hex: "1A1A2E")
    static let deepCharcoal = Color(hex: "0F0F1A")
    static let amberGold = Color(hex: "F59E0B")
    static let sunsetOrange = Color(hex: "F97316")
    static let coralRose = Color(hex: "FB7185")
    static let warmWhite = Color(hex: "FFF7ED")

    // Gradient accent colors
    static let deepPlum = Color(hex: "44204A")
    static let burntAmber = Color(hex: "7C2D12")
    static let darkAmber = Color(hex: "422006")
    static let deepRust = Color(hex: "9A3412")

    // MARK: - Semantic Colors (for use on dark gradient backgrounds)

    static let textPrimary = warmWhite
    static let textSecondary = warmWhite.opacity(0.7)
    static let textTertiary = warmWhite.opacity(0.5)
    static let textDisabled = warmWhite.opacity(0.35)

    static let accent = amberGold
    static let accentText = charcoalBlue   // Dark text on gold buttons
    static let favorite = coralRose

    static let cardBackground = Color.white.opacity(0.07)
    static let cardBackgroundHover = Color.white.opacity(0.12)
    static let inputBackground = Color.white.opacity(0.12)
    static let strokeLight = Color.white.opacity(0.15)

    static let buttonBackground = amberGold
    static let buttonDisabled = warmWhite.opacity(0.30)
    static let destructive = Color(red: 0.9, green: 0.3, blue: 0.3)

    // Selected / unselected chip states
    static let chipSelected = amberGold
    static let chipUnselected = Color.white.opacity(0.12)
    static let chipTextSelected = charcoalBlue
    static let chipTextUnselected = warmWhite

    // MARK: - Heading Fonts (Cormorant Garamond)

    static let largeTitle = heading(34, weight: .bold)
    static let title = heading(28, weight: .bold)
    static let title2 = heading(22, weight: .semibold)
    static let title3 = heading(20, weight: .medium)

    // MARK: - Body Fonts (Inter)

    static let headline = body(17, weight: .semibold)
    static let bodyFont = body(17, weight: .regular)
    static let subheadline = body(15, weight: .medium)
    static let caption = body(12, weight: .regular)
    static let caption2 = body(11, weight: .regular)

    // MARK: - Font Builders

    static func heading(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        let name: String
        switch weight {
        case .medium:
            name = "CormorantGaramond-Medium"
        case .semibold:
            name = "CormorantGaramond-SemiBold"
        case .bold, .heavy, .black:
            name = "CormorantGaramond-Bold"
        default:
            name = "CormorantGaramond-Regular"
        }
        return .custom(name, size: size)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .light, .ultraLight, .thin:
            name = "Inter-Light"
        case .medium:
            name = "Inter-Medium"
        case .semibold:
            name = "Inter-SemiBold"
        case .bold, .heavy, .black:
            name = "Inter-Bold"
        default:
            name = "Inter-Regular"
        }
        return .custom(name, size: size)
    }
}

// MARK: - Color Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}
