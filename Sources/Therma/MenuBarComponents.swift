import SwiftUI
import AppKit

struct MenuStatBox: View {
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
        isOk
            ? Color(red: 0.35, green: 0.92, blue: 0.62)
            : .white.opacity(0.88)
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
        return delta > 0 ? Color(red: 1.0, green: 0.68, blue: 0.34) : Color(red: 0.45, green: 0.88, blue: 0.72)
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
        switch celsius {
        case ..<50:  return Color(red: 0.30, green: 0.82, blue: 1.00)
        case ..<65:  return Color(red: 0.38, green: 0.92, blue: 0.68)
        case ..<78:  return Color(red: 0.98, green: 0.85, blue: 0.28)
        case ..<88:  return Color(red: 1.00, green: 0.58, blue: 0.18)
        default:     return Color(red: 1.00, green: 0.28, blue: 0.32)
        }
    }
}

struct ThemeStripView: View {
    @Binding var selectedThemeName: String
    let statusMessage: String?
    let statusIsSuccess: Bool

    @State private var scrollOffset: CGFloat = 0
    @State private var dragStartOffset: CGFloat = 0
    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 0) {
            if let msg = statusMessage {
                Text(msg.components(separatedBy: "\n").first ?? msg)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(
                        statusIsSuccess
                            ? Color(red: 0.29, green: 0.87, blue: 0.5)
                            : .red
                    )
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
            }

            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 0.5)

            themeScrollView
                .padding(.vertical, 10)
        }
    }

    private var themeScrollView: some View {
        GeometryReader { geometry in
            let totalWidth = Constants.themeItemWidth * CGFloat(ThemeRegistry.all.count) + 24
            let maxOffset = max(0, totalWidth - geometry.size.width)

            HStack(spacing: 5) {
                ForEach(ThemeRegistry.all, id: \.name) { theme in
                    themePreset(theme)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 2)
            .offset(x: -scrollOffset)
            .background(Color.black.opacity(0.001))
            .gesture(themeDragGesture(maxOffset: maxOffset))
        }
        .frame(height: 38)
    }

    private func themeDragGesture(maxOffset: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    dragStartOffset = scrollOffset
                }
                scrollOffset = min(max(dragStartOffset - value.translation.width, 0), maxOffset)
            }
            .onEnded { value in
                isDragging = false
                dragStartOffset = scrollOffset
                let target = min(max(dragStartOffset - value.predictedEndTranslation.width, 0), maxOffset)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    scrollOffset = target
                }
                dragStartOffset = scrollOffset
            }
    }

    private func themePreset(_ theme: AppTheme) -> some View {
        let isActive = theme.name == selectedThemeName
        return themePresetDecoration(theme: theme, isActive: isActive)
            .contentShape(Rectangle())
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isActive)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedThemeName = theme.name
                }
            }
    }

    @ViewBuilder
    private func themePresetDecoration(theme: AppTheme, isActive: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(isActive ? 0.08 : 0.04))
                .frame(width: Constants.themeCircleSize, height: Constants.themeCircleSize)

            Circle()
                .fill(theme.accent)
                .frame(width: isActive ? 18 : 15, height: isActive ? 18 : 15)
                .shadow(color: theme.accent.opacity(isActive ? 0.7 : 0.3), radius: isActive ? 6 : 3)

            if isActive {
                Circle()
                    .fill(theme.accent)
                    .frame(width: Constants.themeActiveDotSize, height: Constants.themeActiveDotSize)
                    .offset(x: 12, y: 12)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? theme.accent : Color.clear, lineWidth: 1.5)
                .shadow(color: isActive ? theme.accent.opacity(0.5) : .clear, radius: 4)
        )
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
