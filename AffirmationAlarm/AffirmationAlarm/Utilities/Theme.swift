import SwiftUI

// MARK: - Brand Theme

enum AppTheme {

    // MARK: - Brand Colors

    static let forestGreen = Color(hex: "2E7D32")
    static let brown = Color(hex: "8D6E63")
    static let gold = Color(hex: "C9A227")
    static let cream = Color(hex: "FAF3E0")

    // Darker variants for gradient backgrounds
    static let deepGreen = Color(hex: "1B5E20")
    static let darkBrown = Color(hex: "5D4037")

    // MARK: - Semantic Colors (for use on dark gradient backgrounds)

    static let textPrimary = cream
    static let textSecondary = cream.opacity(0.7)
    static let textTertiary = cream.opacity(0.5)
    static let textDisabled = cream.opacity(0.35)

    static let accent = gold
    static let accentText = Color(hex: "1B5E20")   // Dark green text on gold buttons
    static let favorite = gold

    static let cardBackground = cream.opacity(0.10)
    static let cardBackgroundHover = cream.opacity(0.15)
    static let inputBackground = cream.opacity(0.15)
    static let strokeLight = cream.opacity(0.20)

    static let buttonBackground = gold
    static let buttonDisabled = cream.opacity(0.30)
    static let destructive = Color(red: 0.9, green: 0.3, blue: 0.3)

    // Selected / unselected chip states
    static let chipSelected = gold
    static let chipUnselected = cream.opacity(0.15)
    static let chipTextSelected = Color(hex: "1B5E20")
    static let chipTextUnselected = cream

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
