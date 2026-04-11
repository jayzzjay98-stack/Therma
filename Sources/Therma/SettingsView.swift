import SwiftUI

// MARK: - Settings Tab

enum SettingsTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case menuBar = "Menu Bar"
    case general = "General"
    case alerts  = "Alerts"
    case about   = "About"

    var id: String { rawValue }

    var title: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .menuBar:   return "menubar.rectangle"
        case .general:   return "gearshape"
        case .alerts:    return "bell"
        case .about:     return "info.circle"
        }
    }

    var accentColor: Color {
        switch self {
        case .dashboard: return Color(red: 0.17, green: 0.80, blue: 0.78)
        case .menuBar:   return Color(red: 0.23, green: 0.51, blue: 0.96)
        case .general:   return Color(red: 0.55, green: 0.36, blue: 0.96)
        case .alerts:    return Color(red: 0.98, green: 0.45, blue: 0.09)
        case .about:     return Color(red: 0.06, green: 0.73, blue: 0.51)
        }
    }

    var iconGradient: LinearGradient {
        switch self {
        case .dashboard:
            return LinearGradient(
                colors: [Color(red: 0.31, green: 0.92, blue: 0.86),
                         Color(red: 0.10, green: 0.48, blue: 0.96)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .menuBar:
            return LinearGradient(
                colors: [Color(red: 0.35, green: 0.57, blue: 1.0),
                         Color(red: 0.15, green: 0.38, blue: 0.90)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .general:
            return LinearGradient(
                colors: [Color(red: 0.66, green: 0.48, blue: 1.0),
                         Color(red: 0.46, green: 0.26, blue: 0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .alerts:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.56, blue: 0.22),
                         Color(red: 0.90, green: 0.33, blue: 0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .about:
            return LinearGradient(
                colors: [Color(red: 0.25, green: 0.85, blue: 0.62),
                         Color(red: 0.04, green: 0.60, blue: 0.40)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    private static let processMonitoringSource = "settings-dashboard"

    @Environment(\.dismiss) var dismiss
    let selectedTheme = AppTheme.midnightAurora

    @Bindable var preferences: MenuBarPreferences
    let ramMonitor: RAMMonitor
    let cpuMonitor: CPUMonitor
    let systemMetricsMonitor: SystemMetricsMonitor
    @ObservedObject var updateManager: UpdateManager
    let closeAction: (() -> Void)?

    @State var selectedTab: SettingsTab = .dashboard
    @State var selectedMenuBarItem: MenuBarItem = .memory
    @State var launchAtLoginManager = LaunchAtLoginManager()
    @State var cleaningInProgress = false
    @State var cleanStatusMessage: String?
    @State var cleanStatusIsSuccess = false
    @State var cleanTimedOut = false

    init(
        preferences: MenuBarPreferences,
        ramMonitor: RAMMonitor,
        cpuMonitor: CPUMonitor,
        systemMetricsMonitor: SystemMetricsMonitor,
        updateManager: UpdateManager,
        closeAction: (() -> Void)? = nil
    ) {
        self.preferences = preferences
        self.ramMonitor = ramMonitor
        self.cpuMonitor = cpuMonitor
        self.systemMetricsMonitor = systemMetricsMonitor
        self.updateManager = updateManager
        self.closeAction = closeAction
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                sidebar
                contentPanel
            }
            SettingsActionBar(
                resetAction: { preferences.reset() },
                closeAction: closeWindow
            )
        }
        .frame(
            width: SettingsLayoutMetrics.totalWidth,
            height: SettingsLayoutMetrics.totalHeight
        )
        .background(SettingsWindowBackground(theme: selectedTheme))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(selectedTheme.borderColor, lineWidth: 1)
        }
        .shadow(color: selectedTheme.accent.opacity(0.05), radius: 40)
        .shadow(color: .black.opacity(0.55), radius: 28, y: 12)
        .environment(\.appTheme, selectedTheme)
        .onAppear {
            launchAtLoginManager.refresh()
            updateProcessMonitoring(for: selectedTab)
        }
        .onChange(of: selectedTab) { _, newValue in
            updateProcessMonitoring(for: newValue)
        }
        .onDisappear {
            ramMonitor.setProcessMonitoring(false, source: Self.processMonitoringSource)
        }
    }

    var contentTitle: String? {
        nil
    }

    func updateProcessMonitoring(for tab: SettingsTab) {
        ramMonitor.setProcessMonitoring(tab == .dashboard, source: Self.processMonitoringSource)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("THERMA")
                    .font(.system(size: 15, weight: .bold, design: .default))
                    .foregroundStyle(selectedTheme.accent)
                    .tracking(3.0)
                    .animation(.easeInOut(duration: 0.3), value: selectedTheme.name)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(SettingsTab.allCases) { tab in
                    SettingsSidebarItem(tab: tab, isSelected: selectedTab == tab) {
                        selectedTab = tab
                    }
                }
            }

            Spacer()
        }
        .frame(width: SettingsLayoutMetrics.sidebarWidth)
        .background(
            selectedTheme.sidebarBgColor
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(selectedTheme.accent.opacity(0.08))
                        .frame(width: 0.5)
                }
        )
    }

    // MARK: - Content Panel

    private var contentPanel: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                if let contentTitle {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contentTitle.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(selectedTheme.accent.opacity(0.92))
                            .tracking(1.8)

                        Text(contentTitle)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }

                switch selectedTab {
                case .dashboard: dashboardPane
                case .menuBar:   menuBarPane
                case .general:   generalPane
                case .alerts:    alertsPane
                case .about:     aboutPane
                }
            }
            .padding(selectedTab == .dashboard ? 14 : 20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.01),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Helpers

    var coreTemperatureProgress: Double {
        let temperature = cpuMonitor.currentCelsius ?? cpuMonitor.hottestCelsius ?? 0
        return min(max((temperature - 30) / 70, 0), 1)
    }

    var batteryTemperatureProgress: Double {
        let temperature = cpuMonitor.batteryCelsius ?? 0
        return min(max((temperature - 25) / 35, 0), 1)
    }

    var cpuTrendText: String {
        guard let delta = cpuMonitor.trendDelta else { return "STABLE" }
        if abs(delta) < 0.2 { return "STABLE" }
        return preferences.formatCelsiusDelta(delta)
    }

    var cpuTrendColor: Color {
        guard let delta = cpuMonitor.trendDelta else { return selectedTheme.accent }
        if abs(delta) < 0.2 { return Color.white.opacity(0.45) }
        return delta > 0
            ? selectedTheme.accent
            : Color(red: 0.36, green: 0.92, blue: 0.68)
    }

    var heroStats: [(String, String)] {
        [
            ("Average", cpuMonitor.averageCelsius.map(preferences.formatCelsius) ?? "--"),
            ("Peak", cpuMonitor.hottestCelsius.map(preferences.formatCelsius) ?? "--"),
            ("Sensors", "\(cpuMonitor.sensors.count)")
        ]
    }

    var heroChartValues: [Double] {
        let history = cpuMonitor.history
        guard !history.isEmpty else { return [38, 40, 39, 48, 37, 61, 45] }
        return history.suffix(12)
    }

    var cpuUsageNumericValue: String {
        systemMetricsMonitor.cpuUsageDisplayValue
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var cpuTemperatureNumericValue: String {
        let value = cpuMonitor.currentCelsius.map(preferences.formatCelsius) ?? "--"
        return numericPortion(of: value)
    }

    var batteryTemperatureNumericValue: String {
        let value = cpuMonitor.batteryCelsius.map(preferences.formatCelsius) ?? "--"
        return numericPortion(of: value)
    }

    var networkDownloadProgress: Double {
        throughputProgress(systemMetricsMonitor.downloadBytesPerSecond ?? 0)
    }

    var networkUploadProgress: Double {
        throughputProgress(systemMetricsMonitor.uploadBytesPerSecond ?? 0)
    }

    var formattedCPUAlertThreshold: String {
        if preferences.temperatureInFahrenheit {
            return "\(Int((preferences.cpuAlertThreshold * 9/5 + 32).rounded()))°F"
        }
        return "\(Int(preferences.cpuAlertThreshold))°C"
    }

    var networkDownBars: [Double] {
        networkBars(
            seed: systemMetricsMonitor.downloadBytesPerSecond ?? 0,
            baseline: [0.30, 0.62, 1.0, 0.50, 0.76]
        )
    }

    var networkUpBars: [Double] {
        networkBars(
            seed: systemMetricsMonitor.uploadBytesPerSecond ?? 0,
            baseline: [0.18, 0.28, 0.42, 0.24, 0.34]
        )
    }

    var pressureColor: Color {
        switch ramMonitor.pressure {
        case .low:
            return Color(red: 0.35, green: 0.92, blue: 0.62)
        case .medium:
            return Color(red: 0.98, green: 0.79, blue: 0.26)
        case .high:
            return Color(red: 1.00, green: 0.40, blue: 0.28)
        }
    }

    var cpuThermalColor: Color {
        thermalColor(for: cpuMonitor.currentCelsius ?? cpuMonitor.hottestCelsius ?? 0)
    }

    var batteryThermalColor: Color {
        thermalColor(for: cpuMonitor.batteryCelsius ?? 0)
    }

    func thermalColor(for celsius: Double) -> Color {
        ThermalPalette.color(for: celsius)
    }

    func sensorHeatProgress(_ celsius: Double) -> Double {
        min(max((celsius - Constants.cpuNormLow) / Constants.cpuNormRange, 0), 1)
    }

    func networkBars(seed: Double, baseline: [Double]) -> [Double] {
        guard seed > 0 else { return baseline }
        let normalized = min(max(seed / 12_000_000, 0.18), 1.0)
        return baseline.enumerated().map { index, value in
            let modulation = 0.10 * Double((index % 3) + 1)
            return min(max(value * (0.55 + normalized) + modulation * normalized, 0.16), 1.0)
        }
    }

    func formattedSwap(_ mb: Double) -> String {
        if mb < 1 { return "0 MB" }
        if mb >= Constants.kbPerMB { return String(format: "%.1f GB", mb / Constants.kbPerMB) }
        return String(format: "%.0f MB", mb)
    }

    func formatMemory(_ mb: Double) -> String {
        mb >= Constants.kbPerMB
            ? String(format: "%.1f GB", mb / Constants.kbPerMB)
            : String(format: "%.0f MB", mb)
    }

    func throughputProgress(_ bytesPerSecond: Double) -> Double {
        min(max(bytesPerSecond / 6_000_000, 0.08), 1.0)
    }

    func numericPortion(of value: String) -> String {
        let allowed = Set("0123456789.-")
        let filtered = value.filter { allowed.contains($0) }
        return filtered.isEmpty ? value : filtered
    }

    func compactSensorName(_ name: String) -> String {
        if name.count <= 8 { return name }
        let components = name.split(separator: " ")
        if let first = components.first {
            return String(first.prefix(8))
        }
        return String(name.prefix(8))
    }

    var appBuildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    func previewValue(for item: MenuBarItem) -> String {
        switch item {
        case .memory:
            return "\(ramMonitor.usagePercent)%"
        case .network:
            return systemMetricsMonitor.networkMenuBarDisplayValue(
                showDownload: preferences.networkShowDownload,
                showUpload: preferences.networkShowUpload
            )
        case .cpu:
            if let celsius = cpuMonitor.currentCelsius {
                return preferences.formatCelsius(celsius)
            }
            return cpuMonitor.thermalLevel.shortLabel
        case .cpuUsage:
            return systemMetricsMonitor.cpuUsageDisplayValue
        }
    }

    func performClean() {
        guard !cleaningInProgress else { return }

        cleaningInProgress = true
        cleanTimedOut = false
        cleanStatusMessage = nil

        scheduleCleanTimeout()

        ramMonitor.deepCleanMemory { success, message in
            Task { @MainActor in
                guard !cleanTimedOut else { return }
                cleaningInProgress = false
                cleanStatusIsSuccess = success
                cleanStatusMessage = message
                scheduleDismissStatus()
            }
        }
    }

    func scheduleCleanTimeout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.cleanTimeoutSeconds) {
            guard self.cleaningInProgress else { return }
            self.cleanTimedOut = true
            self.cleaningInProgress = false
            self.cleanStatusMessage = "Timed out"
            self.cleanStatusIsSuccess = false
            self.scheduleDismissStatus()
        }
    }

    func scheduleDismissStatus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.statusMessageDismissDelay) {
            self.cleanStatusMessage = nil
        }
    }

    func closeWindow() {
        if let closeAction { closeAction() } else { dismiss() }
    }

    func iconSizeBinding(for item: MenuBarItem) -> Binding<Double> {
        switch item {
        case .memory:
            return $preferences.memoryMenuBarIconSize
        case .network:
            return $preferences.networkMenuBarIconSize
        case .cpu:
            return $preferences.cpuMenuBarIconSize
        case .cpuUsage:
            return $preferences.cpuUsageMenuBarIconSize
        }
    }

    func textSizeBinding(for item: MenuBarItem) -> Binding<Double> {
        switch item {
        case .memory:
            return $preferences.memoryMenuBarTextSize
        case .network:
            return $preferences.networkMenuBarTextSize
        case .cpu:
            return $preferences.cpuMenuBarTextSize
        case .cpuUsage:
            return $preferences.cpuUsageMenuBarTextSize
        }
    }
}
