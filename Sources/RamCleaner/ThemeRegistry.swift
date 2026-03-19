import SwiftUI

// MARK: - WCAG Accessibility Verification
//
// All themes use very dark backgrounds (luminance ≈ 0.003–0.008) which yields
// contrast ratios of 19:1–21:1 for full-white text — well above WCAG AA (4.5:1).
//
// Dimmed text used in the UI (white at various opacities) on the darkest theme (AMBER):
//   opacity 0.90 → CR 15.7  PASS
//   opacity 0.78 → CR 11.9  PASS
//   opacity 0.72 → CR 10.2  PASS
//   opacity 0.68 → CR  9.1  PASS
//   opacity 0.62 → CR  7.7  PASS
//   opacity 0.56 → CR  6.4  PASS  (smallest value used in the UI)
//
// Accent colors on their paired backgrounds:
//   AMBER  (orange on near-black)  →  8.4:1  PASS
//   MATRIX (green on near-black)   → 14.4:1  PASS
//   ARCTIC (cyan on near-black)    →  9.9:1  PASS
//   COSMIC (purple on near-black)  →  5.0:1  PASS  ← lowest; still above AA
//   GOLD   (yellow on near-black)  → 11.8:1  PASS
//
// INK / ONYX / NIGHT themes have low-luminance accents; accent is used only for
// decorative highlights (circles, borders), NOT for text, so body text stays white.
// No re-verification needed unless accent is applied to body text in future.

struct AppTheme {
    let name: String
    let accent: Color
    let accentDim: Color
    let bgColor: Color
    let borderColor: Color
}

enum ThemeRegistry {
    static let all: [AppTheme] = [
        .make("AMBER",  accent: (1.0, 0.55, 0.0),  background: (0.06,  0.047, 0.03)),
        .make("MATRIX", accent: (0.0, 1.0, 0.53),  background: (0.027, 0.06,  0.04)),
        .make("ARCTIC", accent: (0.0, 0.78, 1.0),  background: (0.027, 0.05,  0.07)),
        .make("COSMIC", accent: (0.66, 0.33, 0.97), background: (0.047, 0.03,  0.07)),
        .make("ROSE",   accent: (0.98, 0.44, 0.52), background: (0.07,  0.03,  0.06)),
        .make("GOLD",   accent: (0.96, 0.77, 0.09), background: (0.067, 0.055, 0.016)),
        .make("CYAN",   accent: (0.0, 0.9, 0.8),   background: (0.02,  0.06,  0.055)),
        .make("LAVA",   accent: (1.0, 0.23, 0.36), background: (0.067, 0.02,  0.02)),
        .make("LIME",   accent: (0.52, 0.8, 0.09), background: (0.035, 0.06,  0.02)),
        .make("SILVER", accent: (0.69, 0.72, 0.8), background: (0.05,  0.05,  0.06)),
        .make("SUN",    accent: (1.0, 0.85, 0.2),  background: (0.07,  0.06,  0.02)),
        .make("NIGHT",  accent: (0.1, 0.3, 0.8),   background: (0.01,  0.02,  0.06)),
        .make("FOREST", accent: (0.1, 0.5, 0.2),   background: (0.01,  0.04,  0.02)),
        .make("BERRY",  accent: (0.8, 0.2, 0.6),   background: (0.06,  0.01,  0.04)),
        .make("OCEAN",  accent: (0.0, 0.5, 1.0),   background: (0.01,  0.04,  0.08)),
        .make("MINT",   accent: (0.2, 0.9, 0.6),   background: (0.02,  0.07,  0.05)),
        .make("CORAL",  accent: (1.0, 0.5, 0.4),   background: (0.08,  0.04,  0.03)),
        .make("PEACH",  accent: (1.0, 0.7, 0.5),   background: (0.08,  0.05,  0.04)),
        .make("PLUM",   accent: (0.5, 0.2, 0.6),   background: (0.04,  0.01,  0.05)),
        .make("ONYX",   accent: (0.4, 0.4, 0.4),   background: (0.03,  0.03,  0.03)),
        .make("JADE",   accent: (0.0, 0.7, 0.4),   background: (0.01,  0.06,  0.03)),
        .make("RUBY",   accent: (0.9, 0.1, 0.2),   background: (0.07,  0.01,  0.02)),
        .make("TEAL",   accent: (0.1, 0.6, 0.6),   background: (0.01,  0.05,  0.05)),
        .make("BONE",   accent: (0.9, 0.9, 0.8),   background: (0.07,  0.07,  0.06)),
        .make("IRIS",   accent: (0.4, 0.3, 0.9),   background: (0.03,  0.02,  0.07)),
        .make("INK",    accent: (0.1, 0.1, 0.3),   background: (0.01,  0.01,  0.02)),
        .make("MOSS",   accent: (0.3, 0.5, 0.2),   background: (0.02,  0.04,  0.02)),
        .make("SAND",   accent: (0.8, 0.7, 0.5),   background: (0.06,  0.05,  0.04)),
        .make("RUST",   accent: (0.7, 0.3, 0.1),   background: (0.06,  0.02,  0.01)),
        .make("SKY",    accent: (0.4, 0.8, 1.0),   background: (0.03,  0.06,  0.08)),
        .make("WINE",   accent: (0.6, 0.1, 0.2),   background: (0.05,  0.01,  0.02)),
        .make("FLORA",  accent: (0.9, 0.5, 0.8),   background: (0.07,  0.04,  0.06)),
        .make("LEAF",   accent: (0.4, 0.9, 0.3),   background: (0.03,  0.07,  0.02)),
        .make("DUST",   accent: (0.6, 0.5, 0.5),   background: (0.05,  0.04,  0.04)),
        .make("ICE",    accent: (0.7, 0.9, 1.0),   background: (0.05,  0.07,  0.08))
    ]
}

private extension AppTheme {
    static func make(
        _ name: String,
        accent: (Double, Double, Double),
        background: (Double, Double, Double),
        accentOpacity: Double = 0.1,
        borderOpacity: Double = 0.22
    ) -> AppTheme {
        let accent = Color(red: accent.0, green: accent.1, blue: accent.2)
        return AppTheme(
            name: name,
            accent: accent,
            accentDim: accent.opacity(accentOpacity),
            bgColor: Color(red: background.0, green: background.1, blue: background.2),
            borderColor: accent.opacity(borderOpacity)
        )
    }
}
