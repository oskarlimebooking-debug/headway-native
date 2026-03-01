import SwiftUI

enum Theme {
    // MARK: - Colors (matching PWA CSS variables)
    static let bgDeep = Color(hex: "0f0f1a")
    static let bgSurface = Color(hex: "1a1a2e")
    static let bgCard = Color(hex: "252542")
    static let bgElevated = Color(hex: "2d2d4a")

    static let textPrimary = Color(hex: "f0f0f5")
    static let textSecondary = Color(hex: "a0a0b5")
    static let textMuted = Color(hex: "6a6a80")

    static let accent = Color(hex: "7c6aff")
    static let accentSoft = Color(hex: "7c6aff").opacity(0.15)
    static let accentGlow = Color(hex: "7c6aff").opacity(0.4)

    static let success = Color(hex: "4ade80")
    static let warning = Color(hex: "fbbf24")
    static let error = Color(hex: "f87171")

    static let border = Color.white.opacity(0.08)

    // MARK: - Gradients
    static let accentGradient = LinearGradient(
        colors: [accent, Color(hex: "9333ea")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let headerGradient = LinearGradient(
        colors: [accent, Color(hex: "a78bfa")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Radii
    static let radiusSm: CGFloat = 8
    static let radiusMd: CGFloat = 12
    static let radiusLg: CGFloat = 20

    // MARK: - Shadows
    static let shadow = Color.black.opacity(0.3)

    // MARK: - Fonts
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("CrimsonPro-Regular", size: size).weight(weight)
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("DMSans-Regular", size: size).weight(weight)
    }

    // Fallback fonts if custom fonts aren't bundled
    static func serifFallback(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, design: .serif).weight(weight)
    }

    static func sansFallback(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, design: .default).weight(weight)
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
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
