import SwiftUI

// MARK: - Window Background

struct SettingsWindowBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.047, green: 0.055, blue: 0.090)
            RadialGradient(
                colors: [Color(red: 0.40, green: 0.61, blue: 1.0).opacity(0.18), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: SettingsLayoutMetrics.backgroundGlowRadiusBlue
            )
            RadialGradient(
                colors: [Color(red: 0.60, green: 0.97, blue: 1.0).opacity(0.10), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 280
            )
            RadialGradient(
                colors: [Color(red: 0.42, green: 0.28, blue: 0.96).opacity(0.08), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: SettingsLayoutMetrics.backgroundGlowRadiusPurple
            )
        }
    }
}

// MARK: - Sidebar Item

struct SettingsSidebarItem: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? tab.accentColor : .white.opacity(0.42))
                    .frame(width: 18)
                Text(tab.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.48))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tab.accentColor.opacity(0.12))
                        .shadow(color: tab.accentColor.opacity(0.10), radius: 16)
                }
            }
            .overlay(alignment: .trailing) {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(tab.accentColor)
                        .frame(width: 2, height: 24)
                        .padding(.trailing, 1)
                        .shadow(color: tab.accentColor.opacity(0.9), radius: 6)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Menu Bar Source Row

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

// MARK: - Detail Header

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
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            Text(statusText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
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

// MARK: - Preview Stage

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
                    .fill(Color.black.opacity(0.24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            )
        }
    }
}

// MARK: - Pref Group

struct SettingsPrefGroup<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.11, green: 0.12, blue: 0.17), Color(red: 0.09, green: 0.10, blue: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Pref Row

struct SettingsPrefRow<Trailing: View>: View {
    let label: String
    let sublabel: String?
    let showDivider: Bool
    let trailing: Trailing

    init(
        _ label: String,
        sublabel: String? = nil,
        showDivider: Bool = true,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.label = label
        self.sublabel = sublabel
        self.showDivider = showDivider
        self.trailing = trailing()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.88))
                    if let sublabel {
                        Text(sublabel)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
                Spacer()
                trailing
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)

            if showDivider {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 0.5)
                    .padding(.leading, 14)
            }
        }
    }
}

// MARK: - Toggle

struct SettingsToggle: View {
    @Binding var isOn: Bool
    let tint: Color

    var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            .toggleStyle(.switch)
            .tint(tint)
    }
}

// MARK: - Segmented Picker

struct SettingsModePicker: View {
    @Binding var selection: MonitorDisplayMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(MonitorDisplayMode.allCases.enumerated()), id: \.element.id) { index, mode in
                Button {
                    selection = mode
                } label: {
                    Text(mode.title)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(mode == selection ? .white : .white.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(mode == selection
                                      ? Color(red: 0.23, green: 0.51, blue: 0.96)
                                      : Color.clear)
                                .shadow(
                                    color: mode == selection
                                        ? Color(red: 0.23, green: 0.51, blue: 0.96).opacity(0.4)
                                        : .clear,
                                    radius: 6
                                )
                        )
                }
                .buttonStyle(.plain)

                if index < MonitorDisplayMode.allCases.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 1, height: 14)
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Slider Row

struct SettingsSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let tint: Color

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
                Spacer()
                Text("\(Int(value))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(tint.opacity(0.12))
                    )
            }
            .padding(.horizontal, 12)
            .padding(.top, 9)
            .padding(.bottom, 6)

            Slider(value: $value, in: range, step: 1)
                .tint(tint)
                .padding(.horizontal, 12)
                .padding(.bottom, 9)
        }
    }
}

// MARK: - Unit Picker

struct TemperatureUnitPicker: View {
    @Binding var fahrenheit: Bool

    var body: some View {
        HStack(spacing: 0) {
            unitButton("°C", selected: !fahrenheit) { fahrenheit = false }
            unitButton("°F", selected: fahrenheit) { fahrenheit = true }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.07))
        )
    }

    private func unitButton(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selected ? .white : .white.opacity(0.4))
                .frame(width: 36, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(selected ? Color.white.opacity(0.14) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Threshold Badge

struct ThresholdBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color.opacity(0.25), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Menu Bar Preview Chip

struct MenuBarPreviewChip: View {
    let symbolName: String
    let value: String
    let iconSize: Double
    let textSize: Double

    var body: some View {
        HStack(spacing: max(3, clampedTextSize * 0.22)) {
            Image(systemName: symbolName)
                .font(.system(size: clampedIconSize, weight: .regular))
            Text(value)
                .font(.system(size: clampedTextSize, weight: .regular, design: .default))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.3))
                .overlay(Capsule().stroke(Color.white.opacity(0.09), lineWidth: 0.5))
        )
    }

    private var clampedIconSize: Double {
        min(max(iconSize, Constants.minimumMenuBarIconSize), Constants.maximumMenuBarIconSize)
    }

    private var clampedTextSize: Double {
        min(max(textSize, Constants.minimumMenuBarTextSize), Constants.maximumMenuBarTextSize)
    }
}

// MARK: - Dashboard Hero

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

// MARK: - Dashboard Card

struct SettingsDashboardCard<Content: View>: View {
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
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
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
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct SettingsDashboardCardBackground: View {
    let accent: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.11, green: 0.12, blue: 0.17),
                        accent.opacity(0.035),
                        Color(red: 0.09, green: 0.10, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.6
                    )
            )
    }
}

struct SettingsContentHeader: View {
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
                            .fill(Color(red: 0.60, green: 0.97, blue: 1.0))
                            .frame(width: 6, height: 6)
                            .shadow(color: Color(red: 0.60, green: 0.97, blue: 1.0).opacity(0.7), radius: 6)

                        Text("SYSTEM ONLINE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1.1)
                            .foregroundStyle(Color(red: 0.60, green: 0.97, blue: 1.0))
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
        .frame(width: 180, height: 30)
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
                    .fill(color.opacity(0.12))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.26), lineWidth: 0.6)
                    )
            )
    }
}

struct SettingsHeroMetric: View {
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))
                .tracking(1)
        }
    }
}

struct SettingsStatusStrip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.42))
                .tracking(0.9)

            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.84))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

struct SettingsMetricTile: View {
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.42))
                .tracking(0.8)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
        )
    }
}

struct SettingsLineMeter: View {
    let value: Double
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.06))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.55), tint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(10, geometry.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: 8)
    }
}

struct SettingsThermalTrace: View {
    let values: [Double]
    let tint: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(sampleValues.enumerated()), id: \.offset) { _, value in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.45), tint],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: max(10, normalizedHeight(for: value)))
            }
        }
        .frame(height: 42, alignment: .bottom)
    }

    private var sampleValues: [Double] {
        values.isEmpty ? [0, 0, 0, 0, 0, 0] : values
    }

    private func normalizedHeight(for value: Double) -> CGFloat {
        let clamped = min(max(value, Constants.cpuNormLow), Constants.cpuNormHigh)
        let normalized = (clamped - Constants.cpuNormLow) / Constants.cpuNormRange
        return CGFloat(12 + normalized * 40)
    }
}

struct SettingsProcessUsageRow: View {
    let process: RunningProcess
    let rank: Int
    let maxMemoryMB: Double
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Text(String(format: "%02d", rank))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(tint.opacity(0.75))
                .frame(width: 20, alignment: .leading)

            Text(process.name)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.84))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))

                    Capsule()
                        .fill(tint.opacity(0.8))
                        .frame(width: max(8, geometry.size.width * memoryRatio))
                }
            }
            .frame(width: 180, height: 6)

            Text(memoryDisplayValue)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))
                .frame(width: 62, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
        )
    }

    private var memoryRatio: CGFloat {
        guard maxMemoryMB > 0 else { return 0 }
        return CGFloat(process.memoryMB / maxMemoryMB)
    }

    private var memoryDisplayValue: String {
        process.memoryMB >= Constants.kbPerMB
            ? String(format: "%.1f GB", process.memoryMB / Constants.kbPerMB)
            : String(format: "%.0f MB", process.memoryMB)
    }
}

struct SettingsMiniStatusCard: View {
    let title: String
    let value: String
    let accent: Color
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.36))
                .tracking(1)

            HStack(spacing: 10) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(accent)

                Spacer(minLength: 0)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))

                    Capsule()
                        .fill(accent)
                        .frame(width: max(8, geometry.size.width * min(max(progress, 0), 1)))
                        .shadow(color: accent.opacity(0.45), radius: 8)
                }
            }
            .frame(height: 5)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
                )
        )
    }
}

struct SettingsCircularUsageGauge: View {
    let progress: Double
    let value: String
    let caption: String
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 12)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    LinearGradient(
                        colors: [tint.opacity(0.75), tint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.40), radius: 12)

            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text(caption.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.38))
                    .tracking(1)
            }
        }
    }
}

struct SettingsChartHeroCard: View {
    let eyebrow: String
    let value: String
    let trend: String
    let trendColor: Color
    let stats: [(String, String)]
    let values: [Double]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(eyebrow.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.42))
                        .tracking(1.6)

                    HStack(alignment: .bottom, spacing: 10) {
                        Text(value)
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()

                        Text(trend)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(trendColor)
                            .padding(.bottom, 5)
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 28) {
                    ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stat.0.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.32))
                                .tracking(1)
                            Text(stat.1)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))
                        }
                        .padding(.leading, index == 0 ? 20 : 0)
                        .overlay(alignment: .leading) {
                            if index == 0 {
                                Rectangle()
                                    .fill(Color.white.opacity(0.06))
                                    .frame(width: 1, height: 44)
                                    .offset(x: -12)
                            }
                        }
                    }
                }
            }

            SettingsGlowingAreaChart(values: values, tint: tint)
                .frame(height: 108)
        }
        .padding(14)
        .background(SettingsDashboardCardBackground(accent: tint))
    }
}

struct SettingsGlowingAreaChart: View {
    let values: [Double]
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            let normalized = normalizedValues

            ZStack {
                HStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.03))
                            .frame(width: 1)
                        Spacer(minLength: 0)
                    }
                }

                SettingsAreaFillShape(values: normalized)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.20), tint.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                SettingsLineChartShape(values: normalized)
                    .stroke(tint.opacity(0.22), style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
                    .blur(radius: 6)

                SettingsLineChartShape(values: normalized)
                    .stroke(tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .shadow(color: tint.opacity(0.55), radius: 10)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private var normalizedValues: [Double] {
        let raw = values.isEmpty ? [0.18, 0.22, 0.20, 0.44, 0.18, 0.75, 0.38] : values
        let minValue = raw.min() ?? 0
        let maxValue = raw.max() ?? 1
        let spread = max(maxValue - minValue, 0.001)
        return raw.map { 0.10 + (($0 - minValue) / spread) * 0.72 }
    }
}

private struct SettingsLineChartShape: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        guard values.count > 1 else { return Path() }

        let points = values.enumerated().map { index, value in
            CGPoint(
                x: rect.minX + CGFloat(index) * rect.width / CGFloat(values.count - 1),
                y: rect.maxY - CGFloat(value) * rect.height
            )
        }

        var path = Path()
        path.move(to: points[0])

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midX = (previous.x + current.x) / 2
            path.addCurve(
                to: current,
                control1: CGPoint(x: midX, y: previous.y),
                control2: CGPoint(x: midX, y: current.y)
            )
        }

        return path
    }
}

private struct SettingsAreaFillShape: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        guard values.count > 1 else { return Path() }
        let line = SettingsLineChartShape(values: values).path(in: rect)
        var path = line
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct SettingsNetworkTrafficCard: View {
    let title: String
    let downloadValue: String
    let uploadValue: String
    let downBars: [Double]
    let upBars: [Double]
    let tint: Color
    let secondaryTint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NETWORK THROUGHPUT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.38))
                        .tracking(1.4)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    SettingsLegendDot(label: "DOWN", color: tint)
                    SettingsLegendDot(label: "UP", color: secondaryTint)
                }
            }

            SettingsNetworkBarChart(
                downBars: downBars,
                upBars: upBars,
                downColor: tint,
                upColor: secondaryTint
            )
            .frame(height: 58)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                SettingsTransferStat(title: "Download", value: downloadValue, icon: "arrow.down", tint: tint)
                SettingsTransferStat(title: "Upload", value: uploadValue, icon: "arrow.up", tint: secondaryTint)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SettingsDashboardCardBackground(accent: tint))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct SettingsLegendDot: View {
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.42))
        }
    }
}

private struct SettingsNetworkBarChart: View {
    let downBars: [Double]
    let upBars: [Double]
    let downColor: Color
    let upColor: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(zip(paddedDown.indices, paddedDown)), id: \.0) { index, down in
                let up = paddedUp[index]
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(downColor.opacity(index == 2 ? 0.95 : 0.24))
                        .frame(height: 46 * down)
                        .shadow(color: index == 2 ? downColor.opacity(0.40) : .clear, radius: 10)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(upColor.opacity(index == 2 ? 0.95 : 0.30))
                        .frame(height: 18 * up)
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
            }
        }
    }

    private var paddedDown: [CGFloat] {
        normalized(downBars)
    }

    private var paddedUp: [CGFloat] {
        normalized(upBars)
    }

    private func normalized(_ values: [Double]) -> [CGFloat] {
        let source = values.isEmpty ? [0.30, 0.62, 1.0, 0.48, 0.76] : values
        return source.map { CGFloat(min(max($0, 0.16), 1.0)) }
    }
}

private struct SettingsTransferStat: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(tint.opacity(0.10))
                    )

                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.34))
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 0)
            }

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
        )
    }
}

// MARK: - Action Bar

struct SettingsActionBar: View {
    let resetAction: () -> Void
    let closeAction: () -> Void

    var body: some View {
        HStack {
            Text("THERMA CONTROL SURFACE")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.28))
                .tracking(1.2)

            Spacer()

            Button("Reset to defaults", action: resetAction)
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))

            Button("Done", action: closeAction)
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.60, green: 0.97, blue: 1.0))
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color(red: 0.08, green: 0.18, blue: 0.25))
                        .overlay(
                            Capsule()
                                .stroke(Color(red: 0.60, green: 0.97, blue: 1.0).opacity(0.24), lineWidth: 0.6)
                        )
                )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Color.black.opacity(0.26)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 0.5)
                }
        )
    }
}
