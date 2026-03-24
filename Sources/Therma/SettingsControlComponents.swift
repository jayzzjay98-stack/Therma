import SwiftUI

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
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.88))
                    if let sublabel {
                        Text(sublabel)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color(red: 0.23, green: 0.35, blue: 0.42))
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

struct SettingsToggle: View {
    @Binding var isOn: Bool
    let tint: Color

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            SettingsMiniSwitch(isOn: isOn)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsModePicker: View {
    @Environment(\.appTheme) private var theme
    @Binding var selection: MonitorDisplayMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(MonitorDisplayMode.allCases.enumerated()), id: \.element.id) { index, mode in
                Button {
                    selection = mode
                } label: {
                    Text(mode.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(mode == selection ? theme.accent : Color(red: 0.35, green: 0.48, blue: 0.54))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(mode == selection ? theme.accent.opacity(0.18) : Color.clear)
                                .shadow(
                                    color: mode == selection ? theme.accent.opacity(0.12) : .clear,
                                    radius: 4
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
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(Color.white.opacity(0.07), lineWidth: 0.6)
                )
        )
    }
}

struct SettingsSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(red: 0.35, green: 0.48, blue: 0.54))
                .frame(width: 70, alignment: .leading)

            Slider(value: $value, in: range, step: 1)
                .tint(tint)

            Text("\(Int(value))")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(tint)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

struct TemperatureUnitPicker: View {
    @Binding var fahrenheit: Bool

    var body: some View {
        HStack(spacing: 0) {
            unitButton("°C", selected: !fahrenheit) { fahrenheit = false }
            unitButton("°F", selected: fahrenheit) { fahrenheit = true }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                )
        )
    }

    private func unitButton(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(selected ? Color(red: 0.369, green: 0.969, blue: 0.910) : Color(red: 0.35, green: 0.48, blue: 0.54))
                .frame(width: 36, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(selected ? Color(red: 0.369, green: 0.969, blue: 0.910).opacity(0.14) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ThresholdBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(color.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(color.opacity(0.25), lineWidth: 0.5)
                    )
            )
    }
}

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

struct SettingsMiniSwitch: View {
    let isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? Color(red: 0.369, green: 0.969, blue: 0.910).opacity(0.35) : Color(red: 0.369, green: 0.969, blue: 0.910).opacity(0.10))
                .frame(width: 36, height: 20)

            Circle()
                .fill(isOn ? Color(red: 0.369, green: 0.969, blue: 0.910) : Color(red: 0.23, green: 0.35, blue: 0.42))
                .frame(width: 16, height: 16)
                .padding(2)
                .shadow(color: isOn ? Color(red: 0.369, green: 0.969, blue: 0.910).opacity(0.4) : .clear, radius: 6)
        }
    }
}

struct SettingsActionBar: View {
    @Environment(\.appTheme) private var theme
    let resetAction: () -> Void
    let closeAction: () -> Void

    var body: some View {
        HStack {
            Text("THERMA CONTROL SURFACE")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.16, green: 0.29, blue: 0.35))
                .tracking(3.0)

            Spacer()
        }
        .padding(.horizontal, 18)
        .frame(height: 44)
        .background(
            theme.bgColor.opacity(0.92)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(theme.accent.opacity(0.08))
                        .frame(height: 0.5)
                }
        )
        .animation(.easeInOut(duration: 0.4), value: theme.name)
    }
}

struct ThemeGridCell: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    private var isDesignTheme: Bool { theme.name.contains(" ") }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                if isDesignTheme {
                    designPreview
                } else {
                    classicPreview
                }

                Text(theme.name)
                    .font(.system(size: isDesignTheme ? 9 : 8,
                                  weight: isSelected ? .bold : .medium,
                                  design: .monospaced))
                    .foregroundStyle(isSelected ? theme.accent : .white.opacity(0.45))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? theme.accent.opacity(0.10) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? theme.accent.opacity(0.40) : Color.white.opacity(0.06),
                                lineWidth: isSelected ? 1.0 : 0.7
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var designPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(theme.bgColor)
                .frame(height: 38)
                .overlay(
                    ZStack {
                        RadialGradient(
                            colors: [theme.glow1.opacity(0.55), .clear],
                            center: theme.glow1Position,
                            startRadius: 0,
                            endRadius: 30
                        )
                        RadialGradient(
                            colors: [theme.glow2.opacity(0.40), .clear],
                            center: theme.glow2Position,
                            startRadius: 0,
                            endRadius: 25
                        )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isSelected ? theme.accent.opacity(0.55) : theme.accent.opacity(0.18),
                            lineWidth: isSelected ? 1.5 : 0.7
                        )
                )
                .shadow(color: isSelected ? theme.accent.opacity(0.45) : .clear, radius: 6)
        }
    }

    private var classicPreview: some View {
        ZStack {
            Circle()
                .fill(theme.bgColor)
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? theme.accent : theme.accent.opacity(0.25),
                            lineWidth: isSelected ? 2 : 0.8
                        )
                )
                .shadow(color: isSelected ? theme.accent.opacity(0.55) : .clear, radius: 6)

            Circle()
                .fill(theme.accent)
                .frame(width: 14, height: 14)
                .shadow(color: theme.accent.opacity(0.7), radius: 4)
        }
        .frame(width: 36, height: 36)
    }
}
