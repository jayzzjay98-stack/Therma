import SwiftUI

struct SettingsDashboardHero: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let metadata: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(eyebrow.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(accent.opacity(0.88))
                        .tracking(1.2)

                    Text(title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                SettingsStatusBadge(
                    text: metadata,
                    color: accent
                )
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.11, green: 0.12, blue: 0.17),
                            accent.opacity(0.08),
                            Color(red: 0.09, green: 0.10, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.04), lineWidth: 0.6)
                )
        )
    }
}

struct SettingsDashboardCard<Content: View>: View {
    @Environment(\.appTheme) private var theme
    let icon: String
    let title: String
    let subtitle: String?
    let badgeText: String?
    let badgeColor: Color
    let content: Content

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        badgeText: String? = nil,
        badgeColor: Color = .white,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.badgeText = badgeText
        self.badgeColor = badgeColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 34, height: 34)

                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(red: 0.35, green: 0.48, blue: 0.54))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }

                Spacer(minLength: 0)

                if let badgeText {
                    SettingsStatusBadge(text: badgeText, color: badgeColor)
                }
            }

            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SettingsDashboardCardBackground(accent: badgeColor))
        .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius))
    }
}

struct SettingsDashboardMockCard<Content: View>: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.23, green: 0.42, blue: 0.42))
                .tracking(1.3)
                .frame(maxWidth: .infinity, alignment: .center)

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(SettingsDashboardCardBackground(accent: theme.accent))
        .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius))
    }
}

struct SettingsDashboardCardBackground: View {
    @Environment(\.appTheme) private var theme
    let accent: Color

    var body: some View {
        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
            .fill(theme.cardBgColor)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .stroke(theme.cardBorderColor, lineWidth: theme.cardBorderWidth)
            )
            .overlay(alignment: .topLeading) {
                RadialGradient(
                    colors: [accent.opacity(0.08), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: SettingsLayoutMetrics.cardGlowRadius
                )
                .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius))
            }
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [.clear, theme.accent.opacity(0.28), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
                .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius))
            }
    }
}

struct SettingsContentHeader: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let showOnlineStatus: Bool
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 12) {
                Text(title.uppercased())
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                if showOnlineStatus {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 6, height: 6)
                            .shadow(color: theme.accent.opacity(0.7), radius: 6)

                        Text("SYSTEM ONLINE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1.1)
                            .foregroundStyle(theme.accent)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }

            Spacer(minLength: 0)

            SettingsSearchField()

            HStack(spacing: 8) {
                SettingsHeaderIconButton(symbol: "gearshape.fill", action: primaryAction)
                SettingsHeaderIconButton(symbol: "bell.fill", action: secondaryAction)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Color.black.opacity(0.16)
                .background(.ultraThinMaterial.opacity(0.25))
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.04))
                .frame(height: 0.5)
        }
    }
}

private struct SettingsSearchField: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.32))

            Text("Search parameters...")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.30))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(width: SettingsLayoutMetrics.searchFieldWidth, height: 30)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.06))
        )
    }
}

private struct SettingsHeaderIconButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.68))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.04))
                )
        }
        .buttonStyle(.plain)
    }
}

struct SettingsStatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.10))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.26), lineWidth: 0.6)
                    )
            )
    }
}
