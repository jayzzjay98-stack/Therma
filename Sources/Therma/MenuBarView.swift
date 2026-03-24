import SwiftUI

// MARK: - Menu Bar View

struct MenuBarView: View {
    private static let processMonitoringSource = "menu-bar-popover"

    let ramMonitor: RAMMonitor
    let cpuMonitor: CPUMonitor
    let systemMetricsMonitor: SystemMetricsMonitor
    let preferences: MenuBarPreferences
    let displayModeOverride: MonitorDisplayMode?
    let openSettingsAction: () -> Void

    @State private var cleaningInProgress = false
    @State private var statusMessage: String?
    @State private var statusIsSuccess = false
    @State private var cleanTimedOut = false
    private let theme = AppTheme.midnightAurora

    private var displayMode: MonitorDisplayMode {
        displayModeOverride ?? preferences.displayMode
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            dashboardSection
            if displayMode.showsMemory {
                dividerLine("PROCESSES")
                processesSection
                actionButtons
            }
            footerSection
        }
        .frame(width: Constants.menuBarWidth)
        .background(theme.bgColor)
        .environment(\.appTheme, theme)
        .onAppear { updateForegroundTimer(for: displayMode) }
        .onDisappear {
            ramMonitor.setProcessMonitoring(false, source: Self.processMonitoringSource)
        }
        .onChange(of: displayMode) { _, newValue in
            updateForegroundTimer(for: newValue)
        }
    }

    private var headerSection: some View {
        HStack(spacing: 8) {
            Spacer()
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: headerIconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }
            Text("\(ramMonitor.chipName)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.95))
            Text("·")
                .foregroundStyle(.white.opacity(0.3))
            Text(headerSummary)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(theme.accent)
            Spacer()
        }
        .padding(.vertical, 11)
        .background(
            LinearGradient(
                colors: [theme.accent.opacity(0.08), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5)
        }
    }

    private var dashboardSection: some View {
        VStack(spacing: 0) {
            if displayMode.showsMemory {
                memoryDisplay
                statsGrid
                if preferences.isVisible(.network) {
                    networkActivityCard
                }
            }

            if displayMode.showsCPU {
                if displayMode.showsMemory {
                    dividerLine("CPU")
                }
                cpuDisplay
            }
        }
    }

    private var memoryDisplay: some View {
        HStack(alignment: .top, spacing: 12) {
            memoryTextColumn
            Spacer()
            miniRing
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var memoryTextColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MEMORY USAGE")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(0.8)
                .padding(.bottom, 4)

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("\(ramMonitor.usagePercent)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.accent)
                    .shadow(color: theme.accent.opacity(0.25), radius: 10)
                    .monospacedDigit()
                Text("%")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(theme.accent.opacity(0.5))
            }

            Text(String(format: "%.1f GB / %.1f GB", ramMonitor.usedGB, ramMonitor.totalGB))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 2)

            segmentBar
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
    }

    private var segmentBar: some View {
        GeometryReader { geometry in
            let total  = max(8, Int(geometry.size.width / Constants.segmentItemWidth))
            let filled = Int(Double(ramMonitor.usagePercent) / 100.0 * Double(total))

            HStack(spacing: Constants.segmentSpacing) {
                ForEach(0..<total, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(segmentColor(index: i, filled: filled))
                        .frame(height: segmentHeight(i, total: total))
                }
            }
        }
        .frame(height: Constants.segmentBarHeight)
    }

    private func segmentColor(index: Int, filled: Int) -> Color {
        if index < filled       { return theme.accent }
        if index == filled      { return theme.accent.opacity(0.35) }
        return Color.white.opacity(0.05)
    }

    private func segmentHeight(_ i: Int, total: Int) -> CGFloat {
        let mid = Double(total) / 2.0
        return CGFloat(Double(Constants.segmentBarHeight) - abs(Double(i) - mid) * 0.8)
    }

    private var miniRing: some View {
        let freePercent = ramMonitor.totalGB > 0
            ? max(0.0, 1.0 - (ramMonitor.usedGB / ramMonitor.totalGB))
            : 0.0

        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: Constants.miniRingLineWidth)
                .frame(width: Constants.miniRingSize, height: Constants.miniRingSize)

            Circle()
                .trim(from: 0, to: freePercent)
                .stroke(
                    AngularGradient(
                        colors: [theme.accent.opacity(0.6), theme.accent, theme.accent.opacity(0.7)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: Constants.miniRingLineWidth, lineCap: .round)
                )
                .frame(width: Constants.miniRingSize, height: Constants.miniRingSize)
                .rotationEffect(.degrees(-90))
                .shadow(color: theme.accent.opacity(0.4), radius: 6)

            VStack(spacing: 1) {
                Text(String(format: "%.1f", max(0, ramMonitor.totalGB - ramMonitor.usedGB)))
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text("FREE")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(theme.accent.opacity(0.8))
                    .tracking(0.5)
            }
        }
    }

    private var statsGrid: some View {
        HStack(spacing: 4) {
            MenuStatBox(
                label: "PRESSURE",
                value: ramMonitor.pressure.rawValue,
                isOk: ramMonitor.pressure == .low
            )
            MenuStatBox(label: "SWAP", value: formatSwap(ramMonitor.swapUsedMB), isOk: false)
            MenuStatBox(
                label: "CACHED",
                value: String(format: "%.1f GB", ramMonitor.cachedGB),
                isOk: false
            )
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private var networkActivityCard: some View {
        NetworkActivityCard(systemMetricsMonitor: systemMetricsMonitor)
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
    }

    private var cpuDisplay: some View {
        CPUSectionView(
            cpuMonitor: cpuMonitor,
            systemMetricsMonitor: systemMetricsMonitor,
            preferences: preferences,
            topPadding: displayMode.showsMemory ? 2 : 12
        )
    }

    private func formatSwap(_ mb: Double) -> String {
        if mb < 1 { return "0 MB" }
        if mb >= Constants.kbPerMB { return String(format: "%.1f GB", mb / Constants.kbPerMB) }
        return String(format: "%.0f MB", mb)
    }

    private func dividerLine(_ label: String) -> some View {
        ZStack {
            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5)
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .tracking(1)
                .padding(.horizontal, 8)
                .background(theme.bgColor)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }

    private var processesSection: some View {
        VStack(spacing: 1) {
            if ramMonitor.isLoadingProcesses {
                HStack(spacing: 5) {
                    ProgressView().controlSize(.small)
                    Text("Scanning...")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.vertical, 4)
            } else {
                let maxMem = ramMonitor.topProcesses.map(\.memoryMB).max() ?? 1
                ForEach(Array(ramMonitor.topProcesses.enumerated()), id: \.element.id) { i, p in
                    processRow(p, rank: i + 1, maxMem: maxMem)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    private func processRow(_ p: RunningProcess, rank: Int, maxMem: Double) -> some View {
        HStack(spacing: 6) {
            rankLabel(rank)
            processNameLabel(p.name)
            memoryBar(p.memoryMB, maxMem: maxMem)
            memoryValueLabel(p.memoryMB)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
    }

    private func rankLabel(_ rank: Int) -> some View {
        Text(String(format: "%02d", rank))
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(theme.accent.opacity(0.5))
            .frame(width: 14, alignment: .leading)
    }

    private func processNameLabel(_ name: String) -> some View {
        Text(name)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundStyle(.white)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func memoryBar(_ mb: Double, maxMem: Double) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.white.opacity(0.06))
                .frame(width: Constants.processBarWidth, height: 2.5)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(theme.accent.opacity(0.7))
                .frame(width: max(2, Constants.processBarWidth * mb / maxMem), height: 2.5)
        }
        .frame(width: Constants.processBarWidth)
    }

    private func memoryValueLabel(_ mb: Double) -> some View {
        Text(formatMemory(mb))
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.8))
            .frame(width: 48, alignment: .trailing)
    }

    private var actionButtons: some View {
        HStack(spacing: 6) {
            if cleaningInProgress {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small).tint(theme.accent)
                    Text("Clearing RAM...")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }
                .frame(maxWidth: .infinity)
                .frame(height: Constants.actionButtonHeight)
                .background(
                    RoundedRectangle(cornerRadius: 8).fill(theme.accentDim)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.borderColor, lineWidth: 0.5))
                )
            } else {
                Button(action: { performClean() }) {
                    HStack(spacing: 6) {
                        Text("◉").font(.system(size: 17)).foregroundStyle(theme.accent)
                        Text("Clear Ram").font(.system(size: 13, weight: .bold)).foregroundStyle(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.actionButtonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 8).fill(theme.accentDim)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.borderColor, lineWidth: 0.5))
                    )
                }
                .buttonStyle(.plain)
                .keyboardShortcut("c", modifiers: [.command])
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private var footerSection: some View {
        MenuFooterBar(openSettingsAction: openSettingsAction)
    }

    private func formatMemory(_ mb: Double) -> String {
        mb >= Constants.kbPerMB
            ? String(format: "%.1f GB", mb / Constants.kbPerMB)
            : String(format: "%.0f MB", mb)
    }

    private var headerIconName: String {
        switch displayMode {
        case .memory: return "cpu"
        case .cpu:    return "thermometer.medium"
        case .both:   return "square.grid.2x2"
        }
    }

    private var headerSummary: String {
        switch displayMode {
        case .memory:
            return "\(Int(ramMonitor.totalGB))GB"
        case .cpu:
            if let celsius = cpuMonitor.currentCelsius {
                return preferences.formatCelsius(celsius)
            }
            return cpuMonitor.thermalLevel.shortLabel
        case .both:
            return "RAM + CPU"
        }
    }

    private func updateForegroundTimer(for mode: MonitorDisplayMode) {
        ramMonitor.setProcessMonitoring(mode.showsMemory, source: Self.processMonitoringSource)
    }

    private func performClean() {
        cleaningInProgress = true
        cleanTimedOut      = false
        statusMessage      = nil

        scheduleCleanTimeout()

        ramMonitor.deepCleanMemory { [self] success, message in
            Task { @MainActor in
                guard !cleanTimedOut else { return }
                cleaningInProgress = false
                statusIsSuccess    = success
                statusMessage      = message
                scheduleDismissStatus()
            }
        }
    }

    private func scheduleCleanTimeout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.cleanTimeoutSeconds) {
            guard self.cleaningInProgress else { return }
            self.cleanTimedOut      = true
            self.cleaningInProgress = false
            self.statusMessage      = "Timed out"
            self.statusIsSuccess    = false
            self.scheduleDismissStatus()
        }
    }

    private func scheduleDismissStatus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.statusMessageDismissDelay) {
            self.statusMessage = nil
        }
    }
}
