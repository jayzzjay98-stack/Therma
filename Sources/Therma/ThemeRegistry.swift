import SwiftUI

struct AppTheme {
    let name: String
    let accent: Color
    let accentDim: Color
    let bgColor: Color
    let borderColor: Color
    // Background glow layers
    let glow1: Color
    let glow1Position: UnitPoint
    let glow2: Color
    let glow2Position: UnitPoint
    // Visual theme properties
    let sidebarBgColor: Color
    let cardBgColor: Color
    let cardBorderColor: Color
    let cardBorderWidth: CGFloat
    let cardGlowRadius: CGFloat
    let cardCornerRadius: CGFloat
    let hasScanlines: Bool
    let sidebarAccentWidth: CGFloat
    let sidebarAccentColor: Color
}

// MARK: - Midnight Aurora (single fixed design)

extension AppTheme {
    // Accent: #5ef7e8  —  rgb(94,247,232)
    static let midnightAurora = AppTheme(
        name: "MIDNIGHT AURORA",
        accent:       Color(red: 0.369, green: 0.969, blue: 0.910),
        accentDim:    Color(red: 0.369, green: 0.969, blue: 0.910).opacity(0.08),
        bgColor:      Color(red: 0.039, green: 0.055, blue: 0.102),   // #0a0e1a
        borderColor:  Color(red: 0.369, green: 0.969, blue: 0.910).opacity(0.12),
        glow1:        Color(red: 0.369, green: 0.969, blue: 0.910),
        glow1Position: UnitPoint(x: 0.50, y: 0.02),
        glow2:        Color(red: 0.627, green: 0.314, blue: 1.000),
        glow2Position: UnitPoint(x: 1.05, y: 0.12),
        sidebarBgColor: Color(red: 0.047, green: 0.063, blue: 0.110), // #0c101c
        cardBgColor:  Color(red: 0.369, green: 0.969, blue: 0.910).opacity(0.03),
        cardBorderColor: Color(red: 0.369, green: 0.969, blue: 0.910).opacity(0.10),
        cardBorderWidth: 0.85,
        cardGlowRadius: 0,
        cardCornerRadius: 10,
        hasScanlines: false,
        sidebarAccentWidth: 0,
        sidebarAccentColor: Color(red: 0.369, green: 0.969, blue: 0.910)
    )
}

// MARK: - Registry (single entry — theme selection removed)

enum ThemeRegistry {
    static let all: [AppTheme] = [.midnightAurora]
}
