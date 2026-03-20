import SwiftUI

// MARK: - Window Background

struct SettingsWindowBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.10)
            RadialGradient(
                colors: [Color(red: 0.20, green: 0.42, blue: 1.0).opacity(0.22), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: SettingsLayoutMetrics.backgroundGlowRadiusBlue
            )
            RadialGradient(
                colors: [Color(red: 0.58, green: 0.22, blue: 0.98).opacity(0.14), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: SettingsLayoutMetrics.backgroundGlowRadiusPurple
            )
            RadialGradient(
                colors: [Color(red: 0.98, green: 0.45, blue: 0.20).opacity(0.05), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: SettingsLayoutMetrics.backgroundGlowRadiusWarm
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
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(tab.iconGradient)
                        .frame(width: 32, height: 32)
                        .shadow(color: tab.accentColor.opacity(isSelected ? 0.6 : 0.15), radius: isSelected ? 8 : 4)
                    Image(systemName: tab.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(tab.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.09))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(tab.accentColor.opacity(0.25), lineWidth: 0.5)
                        )
                }
            }
            .overlay(alignment: .leading) {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(tab.accentColor)
                        .frame(width: 3, height: 20)
                        .padding(.leading, 1)
                        .shadow(color: tab.accentColor.opacity(0.8), radius: 4)
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
                        colors: [Color.white.opacity(0.055), Color.white.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
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

// MARK: - Action Bar

struct SettingsActionBar: View {
    let resetAction: () -> Void
    let closeAction: () -> Void

    var body: some View {
        HStack {
            Button("Reset to defaults", action: resetAction)
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))

            Spacer()

            Button("Done", action: closeAction)
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.23, green: 0.51, blue: 0.96))
                .controlSize(.regular)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(
            Color.black.opacity(0.22)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 0.5)
                }
        )
    }
}
