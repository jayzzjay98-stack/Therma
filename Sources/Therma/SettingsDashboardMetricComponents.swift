import SwiftUI

struct SettingsHeroMetric: View {
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
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
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.6)
                )
        )
    }
}

struct SettingsDashboardValue: View {
    let value: String
    let unit: String?

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text(value)
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let unit, !unit.isEmpty {
                Text(unit)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(red: 0.23, green: 0.42, blue: 0.42))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct SettingsCompactBarRow: View {
    let label: String
    let value: String
    let progress: Double
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(tint)
                .frame(width: 26, alignment: .trailing)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.55), tint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(max(progress, 0), 1))
                }
            }
            .frame(height: 8)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 82, alignment: .trailing)
        }
    }
}

struct SettingsSensorHeatRow: View {
    let name: String
    let value: String
    let progress: Double
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(red: 0.35, green: 0.48, blue: 0.54))
                .lineLimit(1)
                .frame(width: 62, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.5), tint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(max(progress, 0), 1))
                }
            }
            .frame(height: 10)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(tint)
                .frame(width: 46, alignment: .trailing)
        }
    }
}

struct SettingsSourceToggleRow: View {
    @Environment(\.appTheme) private var theme
    let icon: String
    let label: String
    let subtitle: String
    let isOn: Bool
    let isSelected: Bool
    let selectAction: () -> Void
    let toggleAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: selectAction) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? theme.accent.opacity(0.12) : Color.white.opacity(0.04))
                            .frame(width: 34, height: 34)

                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isSelected ? theme.accent : .white.opacity(0.72))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.90))

                        Text(subtitle)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(isSelected ? theme.accent.opacity(0.80) : .white.opacity(0.34))
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: toggleAction) {
                Text(label)
                    .hidden()
                    .overlay {
                        SettingsMiniSwitch(isOn: isOn)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? theme.accent.opacity(0.10) : Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? theme.accent.opacity(0.22) : Color.white.opacity(0.05), lineWidth: 0.8)
                )
        )
    }
}

struct SettingsAlertBlock<Content: View>: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let isOn: Bool
    let toggleAction: () -> Void
    let footer: String
    let content: Content

    init(
        title: String,
        isOn: Bool,
        toggleAction: @escaping () -> Void,
        footer: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isOn = isOn
        self.toggleAction = toggleAction
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Spacer(minLength: 0)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                Spacer(minLength: 0)

                Button(action: toggleAction) {
                    SettingsMiniSwitch(isOn: isOn)
                }
                .buttonStyle(.plain)
            }

            content

            Text(footer)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color(red: 0.23, green: 0.35, blue: 0.42))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.cardBgColor)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(theme.cardBorderColor.opacity(0.8), lineWidth: theme.cardBorderWidth)
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
        return Constants.traceBarMinHeight + CGFloat(normalized) * Constants.traceBarHeightRange
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
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.23, green: 0.35, blue: 0.42))
                .tracking(2)

            HStack(spacing: 10) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
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
            RoundedRectangle(cornerRadius: 8)
                .fill(accent.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(accent.opacity(0.10), lineWidth: 0.8)
                )
        )
    }
}
