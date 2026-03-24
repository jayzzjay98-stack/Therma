import SwiftUI
import AppKit

struct MenuStatBox: View {
    @Environment(\.appTheme) private var theme
    let label: String
    let value: String
    let isOk: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))
                .tracking(0.8)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(cardBackground)
    }

    private var valueColor: Color {
        isOk ? theme.accent : .white.opacity(0.88)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
    }
}

struct NetworkActivityCard: View {
    let systemMetricsMonitor: SystemMetricsMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NETWORK")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.56))
                .tracking(0.8)

            HStack(spacing: 4) {
                MenuStatBox(
                    label: "DOWN",
                    value: systemMetricsMonitor.downloadSpeedDisplayValue,
                    isOk: true
                )
                MenuStatBox(
                    label: "UP",
                    value: systemMetricsMonitor.uploadSpeedDisplayValue,
                    isOk: false
                )
            }
        }
        .padding(12)
        .background(MenuCardBackground())
    }
}

struct CPUSectionView: View {
    @Environment(\.appTheme) private var theme
    let cpuMonitor: CPUMonitor
    let systemMetricsMonitor: SystemMetricsMonitor
    let preferences: MenuBarPreferences
    let topPadding: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            cpuHistoryCard
            cpuSensorsCard
            batteryTemperatureCard

            HStack(spacing: 4) {
                MenuStatBox(
                    label: "CURRENT",
                    value: cpuMonitor.currentCelsius.map { preferences.formatCelsius($0) } ?? cpuMonitor.thermalLevel.shortLabel,
                    isOk: !cpuMonitor.thermalLevel.isWarning
                )

                if preferences.isVisible(.cpuUsage) {
                    MenuStatBox(
                        label: "USAGE",
                        value: systemMetricsMonitor.cpuUsageDisplayValue,
                        isOk: (systemMetricsMonitor.cpuUsagePercent ?? 0) < 70
                    )
                }

            }
        }
        .padding(.horizontal, 14)
        .padding(.top, topPadding)
        .padding(.bottom, 10)
    }

    private var cpuHistoryValues: [Double] {
        cpuMonitor.history.isEmpty ? [0] : cpuMonitor.history
    }

    private var cpuTrendText: String {
        guard let delta = cpuMonitor.trendDelta else { return "STABLE" }
        if abs(delta) < 0.2 { return "STABLE" }
        return preferences.formatCelsiusDelta(delta)
    }

    private var cpuTrendColor: Color {
        guard let delta = cpuMonitor.trendDelta else { return .white.opacity(0.65) }
        if abs(delta) < 0.2 { return .white.opacity(0.65) }
        return delta > 0 ? Color(red: 1.0, green: 0.68, blue: 0.34) : theme.accent
    }

    private var batteryStatusText: String {
        guard let value = cpuMonitor.batteryCelsius else { return "NO DATA" }
        switch value {
        case ..<35:
            return "NORMAL"
        case ..<40:
            return "WARM"
        case ..<45:
            return "HOT"
        default:
            return "HIGH"
        }
    }

    private var batteryValueColor: Color {
        guard let value = cpuMonitor.batteryCelsius else { return .white.opacity(0.85) }
        return thermalColor(for: value)
    }

    private var batteryTemperatureCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BATTERY TEMP")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.56))
                .tracking(0.8)

            HStack(alignment: .center, spacing: 0) {
                Text(cpuMonitor.batteryCelsius.map { preferences.formatCelsius($0) } ?? "--")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(batteryValueColor)
                    .monospacedDigit()
                    .fixedSize()

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    capsuleLabel(cpuMonitor.batteryCycleDisplayValue, emphasis: .white.opacity(0.74))
                    capsuleLabel(batteryStatusText, emphasis: .white.opacity(0.62))
                }
                .padding(.trailing, 4)
            }
        }
        .padding(12)
        .background(MenuCardBackground())
    }

    private var cpuHistoryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("THERMAL TRACE")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.56))
                    .tracking(0.8)
                Spacer()
                Text(cpuTrendText)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(cpuTrendColor)
            }

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(cpuHistoryValues.enumerated()), id: \.offset) { _, value in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(cpuGradient(for: value))
                        .frame(maxWidth: .infinity)
                        .frame(height: cpuHistoryBarHeight(for: value))
                }
            }
            .frame(height: 48, alignment: .bottom)
        }
        .padding(12)
        .background(MenuCardBackground())
    }

    private var cpuSensorsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("HOTTEST SENSORS")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.56))
                    .tracking(0.8)
                Spacer()
                Text(cpuMonitor.hottestSensorName ?? "Unavailable")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
            }

            if cpuMonitor.sensors.isEmpty {
                Text("No CPU die sensors are readable on this Mac right now.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.62))
            } else {
                VStack(spacing: 6) {
                    ForEach(cpuMonitor.sensors) { sensor in
                        cpuSensorRow(sensor)
                    }
                }
            }
        }
        .padding(12)
        .background(MenuCardBackground())
    }

    private func cpuSensorRow(_ sensor: CPUTemperatureSensor) -> some View {
        HStack(spacing: 8) {
            Text(sensor.name.uppercased())
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(cpuGradient(for: sensor.celsius))
                        .frame(width: max(6, geometry.size.width * cpuNormalized(sensor.celsius)))
                }
            }
            .frame(width: 72, height: 6)

            Text(preferences.formatCelsius(sensor.celsius))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .frame(width: 40, alignment: .trailing)
        }
    }

    private func capsuleLabel(_ text: String, emphasis: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(emphasis)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.06))
            )
    }

    private func cpuHistoryBarHeight(for value: Double) -> CGFloat {
        let normalized = cpuNormalized(value)
        return max(8, 10 + normalized * 38)
    }

    private func cpuNormalized(_ value: Double) -> CGFloat {
        let clamped = min(max(value, Constants.cpuNormLow), Constants.cpuNormHigh)
        return CGFloat((clamped - Constants.cpuNormLow) / Constants.cpuNormRange)
    }

    private func cpuGradient(for value: Double) -> LinearGradient {
        let color = thermalColor(for: value)
        return LinearGradient(
            colors: [color.opacity(0.7), color],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private func thermalColor(for celsius: Double) -> Color {
        ThermalPalette.color(for: celsius)
    }
}

struct MenuFooterBar: View {
    let openSettingsAction: () -> Void

    var body: some View {
        HStack {
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack(spacing: 4) {
                    Text("⏻").font(.system(size: 11))
                    Text("Quit").font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                openSettingsAction()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Settings")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(.white.opacity(0.68))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 0.5)
        }
    }
}

private struct MenuCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.065), Color.white.opacity(0.028)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.6
                    )
            )
    }
}
