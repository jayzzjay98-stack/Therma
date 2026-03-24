import SwiftUI

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .midnightAurora
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

struct SettingsWindowBackground: View {
    let theme: AppTheme

    var body: some View {
        ZStack {
            theme.bgColor
            RadialGradient(
                colors: [theme.glow1.opacity(0.07), theme.glow1.opacity(0.03), .clear],
                center: theme.glow1Position,
                startRadius: 0,
                endRadius: SettingsLayoutMetrics.backgroundGlowRadiusBlue
            )
            RadialGradient(
                colors: [theme.glow2.opacity(0.05), .clear],
                center: theme.glow2Position,
                startRadius: 0,
                endRadius: SettingsLayoutMetrics.backgroundGlowRadiusPurple
            )
        }
        .animation(.easeInOut(duration: 0.4), value: theme.name)
    }
}
