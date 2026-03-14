import SwiftUI

struct PickleProColors {
    // Primary accent - vibrant pickleball yellow-green
    static let accent = Color(hex: "ADFF2F")
    // Slightly cooler variant
    static let accentAlt = Color(hex: "7FFF00")
    // Teal/cyan for CTAs
    static let teal = Color(hex: "2DD4BF")
    // Warm highlight
    static let gold = Color(hex: "FFD700")

    // Backgrounds
    static let background = Color.black
    static let cardBackground = Color(hex: "1A1A1A")
    static let cardBackgroundElevated = Color(hex: "242424")
    static let surfaceLight = Color(hex: "2A2A2A")

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "9CA3AF")
    static let textTertiary = Color(hex: "6B7280")

    // Semantic
    static let success = Color(hex: "34D399")
    static let warning = Color(hex: "FBBF24")
    static let error = Color(hex: "F87171")
    static let info = Color(hex: "60A5FA")

    // Gradients
    static let accentGradient = LinearGradient(
        colors: [accent, accentAlt],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let tealGradient = LinearGradient(
        colors: [teal, Color(hex: "06B6D4")],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let cardGradient = LinearGradient(
        colors: [cardBackground, cardBackgroundElevated],
        startPoint: .top,
        endPoint: .bottom
    )
}

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
