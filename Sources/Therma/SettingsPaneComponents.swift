import SwiftUI

struct SettingsSidebarItem: View {
    @Environment(\.appTheme) private var theme
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? theme.accent : Color(red: 0.35, green: 0.48, blue: 0.54))
                    .frame(width: 22)
                Text(tab.title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? theme.accent : Color(red: 0.35, green: 0.48, blue: 0.54))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(theme.accent.opacity(0.05))
                        .shadow(color: theme.accent.opacity(0.08), radius: 12)
                }
            }
            .overlay(alignment: .leading) {
                if isSelected {
                    Rectangle()
                        .fill(theme.accent)
                        .frame(width: 3)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

struct MenuBarSettingsSourceRow: View {
    let item: MenuBarItem
    let isSelected: Bool
    let isVisible: Bool
    let action: () -> Void
    let toggleAction: (Bool) -> Void
    let showDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button(action: action) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9)
                                .fill(Color.white.opacity(isSelected ? 0.12 : 0.05))
                                .frame(width: 32, height: 32)
                            Image(systemName: item.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(isSelected ? .white : .white.opacity(0.72))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.90))
                            Text(isVisible ? "Visible" : "Hidden")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(isVisible ? item.accentColor : .white.opacity(0.30))
                        }

                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Toggle(
                    "",
                    isOn: Binding(
                        get: { isVisible },
                        set: toggleAction
                    )
                )
                .labelsHidden()
                .toggleStyle(.switch)
                .scaleEffect(0.78)
                .tint(item.accentColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(item.accentColor.opacity(0.22), lineWidth: 0.5)
                        )
                }
            }
            .overlay(alignment: .leading) {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(item.accentColor)
                        .frame(width: 3, height: 24)
                        .padding(.leading, 1)
                }
            }

            if showDivider {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 0.5)
                    .padding(.leading, 14)
            }
        }
    }
}

struct SettingsDetailHeader: View {
    let icon: String
    let title: String
    let subtitle: String?
    let statusText: String
    let accentColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.88))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(red: 0.23, green: 0.35, blue: 0.42))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            Text(statusText)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(accentColor.opacity(0.12))
                        .overlay(
                            Capsule()
                                .stroke(accentColor.opacity(0.24), lineWidth: 0.5)
                        )
                )
        }
    }
}

struct SettingsPreviewStage<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                content
                Spacer()
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.025))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.07), lineWidth: 0.6)
                    )
            )
        }
    }
}

struct SettingsPrefGroup<Content: View>: View {
    @Environment(\.appTheme) private var theme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.cardBgColor)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(theme.cardBorderColor, lineWidth: theme.cardBorderWidth)
                        .shadow(color: theme.cardBorderColor.opacity(theme.cardGlowRadius > 0 ? 0.7 : 0),
                                radius: theme.cardGlowRadius, x: 0, y: 0)
                )
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [.clear, theme.accent.opacity(0.28), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)
                    .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius))
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius))
    }
}

struct SettingsSectionTitle: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(Color(red: 0.23, green: 0.42, blue: 0.42))
            .tracking(2)
    }
}

struct SettingsPaneHero: View {
    @Environment(\.appTheme) private var theme
    let icon: String
    let title: String
    let subtitle: String
    let pills: [String]

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.cardBgColor,
                            theme.accent.opacity(0.08),
                            Color.white.opacity(0.012)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(theme.cardBorderColor, lineWidth: 0.9)
                )

            RadialGradient(
                colors: [theme.accent.opacity(0.12), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 180
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))

            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [theme.accent.opacity(0.22), theme.accent.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.accent.opacity(0.22), lineWidth: 1)
                        )
                        .frame(width: 58, height: 58)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)

                    if !pills.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(pills, id: \.self) { pill in
                                SettingsHeroPill(text: pill)
                            }
                        }
                        .padding(.top, 4)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(20)
        }
    }
}

private struct SettingsHeroPill: View {
    @Environment(\.appTheme) private var theme
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(theme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(theme.accent.opacity(0.10))
                    .overlay(
                        Capsule()
                            .stroke(theme.accent.opacity(0.18), lineWidth: 0.7)
                    )
            )
    }
}

struct SettingsPanelCard<Content: View>: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let subtitle: String?
    let centeredHeader: Bool
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        centeredHeader: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.centeredHeader = centeredHeader
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: centeredHeader ? .center : .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: centeredHeader ? .center : .leading)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.54))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(centeredHeader ? .center : .leading)
                        .frame(maxWidth: .infinity, alignment: centeredHeader ? .center : .leading)
                }
            }

            content
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBgColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.cardBorderColor, lineWidth: 0.9)
                )
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [.clear, theme.accent.opacity(0.24), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
        )
    }
}

struct SettingsMiniStatCard: View {
    @Environment(\.appTheme) private var theme
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.36))
                .tracking(1.1)

            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.6)
                )
        )
    }
}
