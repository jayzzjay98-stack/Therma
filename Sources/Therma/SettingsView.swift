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
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedThemeName") private var selectedThemeName: String = ThemeRegistry.all[0].name

    @Bindable var preferences: MenuBarPreferences
    let ramMonitor: RAMMonitor
    let cpuMonitor: CPUMonitor
    let systemMetricsMonitor: SystemMetricsMonitor
    @ObservedObject var updateManager: UpdateManager
    let closeAction: (() -> Void)?

    @State private var selectedTab: SettingsTab = .dashboard
    @State private var selectedMenuBarItem: MenuBarItem = .memory
    @State private var launchAtLoginManager = LaunchAtLoginManager()
    @State private var cleaningInProgress = false
    @State private var cleanStatusMessage: String?
    @State private var cleanStatusIsSuccess = false
    @State private var cleanTimedOut = false

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
        .background(SettingsWindowBackground())
        .onAppear {
            launchAtLoginManager.refresh()
            ramMonitor.startForegroundTimer()
        }
        .onDisappear {
            ramMonitor.stopForegroundTimer()
        }
    }

    private var selectedTheme: AppTheme {
        ThemeRegistry.all.first { $0.name == selectedThemeName } ?? ThemeRegistry.all[0]
    }

    private var contentTitle: String? {
        switch selectedTab {
        case .dashboard:
            return nil
        case .menuBar, .general, .alerts, .about:
            return selectedTab.title
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("THERMA")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.60, green: 0.97, blue: 1.0))
                    .tracking(1.6)

                Text("v\(Constants.appVersion)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.28))
                    .tracking(1.2)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(SettingsTab.allCases) { tab in
                    SettingsSidebarItem(tab: tab, isSelected: selectedTab == tab) {
                        selectedTab = tab
                    }
                }
            }

            Spacer()

            SettingsMiniStatusCard(
                title: "Core Temp",
                value: cpuMonitor.currentCelsius.map(preferences.formatCelsius) ?? cpuMonitor.thermalLevel.shortLabel,
                accent: Color(red: 0.60, green: 0.97, blue: 1.0),
                progress: coreTemperatureProgress
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: SettingsLayoutMetrics.sidebarWidth)
        .background(
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.08, blue: 0.13).opacity(0.92),
                         Color(red: 0.05, green: 0.07, blue: 0.12).opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .background(.ultraThinMaterial)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 0.5)
            }
        )
    }

    // MARK: - Content Panel

    private var contentPanel: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                if let contentTitle {
                    Text(contentTitle)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
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
    }

    // MARK: - Dashboard Pane

    private var dashboardPane: some View {
        GeometryReader { proxy in
            let spacing = SettingsLayoutMetrics.dashboardGridSpacing
            let width = max(180, (proxy.size.width - (spacing * 2)) / 3)

            VStack(spacing: spacing) {
                HStack(alignment: .top, spacing: spacing) {
                    dashboardCardSlot(dashboardUsageTrendCard, width: width)
                    dashboardCardSlot(dashboardMemoryCard, width: width)
                    dashboardCardSlot(dashboardActivityCard, width: width)
                }

                HStack(alignment: .top, spacing: spacing) {
                    dashboardCardSlot(dashboardCPUCard, width: width)
                    dashboardCardSlot(dashboardSensorHeatCard, width: width)
                    dashboardCardSlot(dashboardBatteryCard, width: width)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: SettingsLayoutMetrics.dashboardCanvasHeight)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func dashboardCardSlot<V: View>(_ view: V, width: CGFloat) -> some View {
        view
            .frame(width: width, height: SettingsLayoutMetrics.dashboardCardHeight, alignment: .topLeading)
            .clipped()
    }

    private var dashboardUsageTrendCard: some View {
        SettingsDashboardCard(
            icon: "waveform.path",
            title: "CPU Usage",
            subtitle: "Live trend",
            badgeText: systemMetricsMonitor.cpuUsageDisplayValue,
            badgeColor: Color(red: 0.60, green: 0.97, blue: 1.0)
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text(systemMetricsMonitor.cpuUsageDisplayValue)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(cpuTrendText)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(cpuTrendColor)
                        .padding(.bottom, 6)
                }

                SettingsGlowingAreaChart(
                    values: heroChartValues,
                    tint: Color(red: 0.60, green: 0.97, blue: 1.0)
                )
                .frame(height: 86)
            }
        }
        .frame(height: SettingsLayoutMetrics.dashboardCardHeight, alignment: .top)
    }

    private var dashboardMemoryCard: some View {
        SettingsDashboardCard(
            icon: "memorychip",
            title: "RAM Usage",
            subtitle: "Memory allocation",
            badgeText: ramMonitor.pressure.rawValue.uppercased(),
            badgeColor: Color(red: 0.42, green: 0.61, blue: 1.0)
        ) {
            VStack(alignment: .center, spacing: 12) {
                SettingsCircularUsageGauge(
                    progress: Double(ramMonitor.usagePercent) / 100.0,
                    value: "\(ramMonitor.usagePercent)%",
                    caption: "Used",
                    tint: Color(red: 0.42, green: 0.61, blue: 1.0)
                )
                .frame(width: 96, height: 96)

                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.30))
                            .tracking(1)
                        Text(String(format: "%.1f GB", ramMonitor.usedGB))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.42, green: 0.61, blue: 1.0))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 1, height: 34)

                    VStack(spacing: 4) {
                        Text("TOTAL")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.30))
                            .tracking(1)
                        Text(String(format: "%.1f GB", ramMonitor.totalGB))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.03))
                )
            }
        }
        .frame(height: SettingsLayoutMetrics.dashboardCardHeight, alignment: .top)
    }

    private var dashboardCPUCard: some View {
        SettingsDashboardCard(
            icon: "thermometer.medium",
            title: "CPU Thermal",
            subtitle: "Temperature trace",
            badgeText: cpuMonitor.thermalLevel.shortLabel,
            badgeColor: cpuThermalColor
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    SettingsHeroMetric(
                        value: cpuMonitor.currentCelsius.map(preferences.formatCelsius) ?? cpuMonitor.thermalLevel.shortLabel,
                        label: "Current",
                        tint: cpuThermalColor
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        SettingsStatusStrip(
                            label: "CPU Usage",
                            value: systemMetricsMonitor.cpuUsageDisplayValue
                        )
                        SettingsStatusStrip(
                            label: "Hottest Sensor",
                            value: cpuMonitor.hottestSensorName ?? "Unavailable"
                        )
                    }
                }

                SettingsThermalTrace(
                    values: cpuMonitor.history,
                    tint: cpuThermalColor
                )

                HStack(spacing: 8) {
                    SettingsMetricTile(
                        label: "Average",
                        value: cpuMonitor.averageCelsius.map(preferences.formatCelsius) ?? "--",
                        tint: Color(red: 0.34, green: 0.86, blue: 0.95)
                    )
                    SettingsMetricTile(
                        label: "Peak",
                        value: cpuMonitor.hottestCelsius.map(preferences.formatCelsius) ?? "--",
                        tint: cpuThermalColor
                    )
                }
            }
        }
        .frame(height: SettingsLayoutMetrics.dashboardCardHeight, alignment: .top)
    }

    private var dashboardSensorHeatCard: some View {
        SettingsDashboardCard(
            icon: "cpu",
            title: "Sensor Heat",
            subtitle: "Top hot spots",
            badgeText: "\(min(cpuMonitor.sensors.count, 4)) SENSORS",
            badgeColor: Color(red: 0.98, green: 0.79, blue: 0.26)
        ) {
            VStack(spacing: 10) {
                if cpuMonitor.sensors.isEmpty {
                    Text("No readable CPU sensors right now.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                } else {
                    ForEach(Array(cpuMonitor.sensors.prefix(3).enumerated()), id: \.element.id) { _, sensor in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(sensor.name.uppercased())
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.54))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                Spacer()
                                Text(preferences.formatCelsius(sensor.celsius))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(thermalColor(for: sensor.celsius))
                            }

                            SettingsLineMeter(
                                value: sensorHeatProgress(sensor.celsius),
                                tint: thermalColor(for: sensor.celsius)
                            )
                        }
                    }
                }
            }
        }
        .frame(height: SettingsLayoutMetrics.dashboardCardHeight, alignment: .top)
    }

    private var dashboardBatteryCard: some View {
        SettingsDashboardCard(
            icon: "battery.75",
            title: "Battery Temp",
            subtitle: "Battery status",
            badgeText: nil,
            badgeColor: batteryThermalColor
        ) {
            VStack(alignment: .center, spacing: 12) {
                SettingsCircularUsageGauge(
                    progress: batteryTemperatureProgress,
                    value: cpuMonitor.batteryCelsius.map(preferences.formatCelsius) ?? "--",
                    caption: "Battery",
                    tint: batteryThermalColor
                )
                .frame(width: 88, height: 88)

                SettingsMetricTile(
                    label: "Charge Cycles",
                    value: cpuMonitor.batteryCycleDisplayValue,
                    tint: batteryThermalColor
                )
            }
        }
        .frame(height: SettingsLayoutMetrics.dashboardCardHeight, alignment: .top)
    }

    private var dashboardActivityCard: some View {
        SettingsNetworkTrafficCard(
            title: "Traffic Analysis",
            downloadValue: systemMetricsMonitor.downloadSpeedDisplayValue,
            uploadValue: systemMetricsMonitor.uploadSpeedDisplayValue,
            downBars: networkDownBars,
            upBars: networkUpBars,
            tint: Color(red: 0.52, green: 0.90, blue: 0.95),
            secondaryTint: Color(red: 0.38, green: 0.55, blue: 0.90)
        )
        .frame(height: SettingsLayoutMetrics.dashboardCardHeight, alignment: .top)
    }

    private var dashboardQuickActionsCard: some View {
        SettingsDashboardCard(
            icon: "slider.horizontal.3",
            title: "Quick Actions",
            subtitle: "Frequently used controls without leaving the dashboard.",
            badgeText: launchAtLoginManager.isEnabled ? "READY" : "MANUAL",
            badgeColor: selectedTheme.accent
        ) {
            VStack(alignment: .leading, spacing: 0) {
                SettingsPrefRow(
                    "Launch at Login",
                    sublabel: launchAtLoginManager.requiresApproval
                        ? "Approval still required in System Settings."
                        : "Start Therma automatically on boot.",
                    showDivider: true
                ) {
                    SettingsToggle(
                        isOn: Binding(
                            get: { launchAtLoginManager.isEnabled },
                            set: { launchAtLoginManager.setEnabled($0) }
                        ),
                        tint: selectedTheme.accent
                    )
                }

                SettingsPrefRow("Temperature Unit", sublabel: "Dashboard and menu bar display format.", showDivider: true) {
                    TemperatureUnitPicker(fahrenheit: $preferences.temperatureInFahrenheit)
                }

                SettingsPrefRow("Software Update", sublabel: updateSubtitle, showDivider: false) {
                    updateControls
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Button(action: performClean) {
                    HStack(spacing: 10) {
                        if cleaningInProgress {
                            ProgressView()
                                .controlSize(.small)
                                .tint(selectedTheme.accent)
                        } else {
                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.system(size: 14, weight: .semibold))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(cleaningInProgress ? "Clearing RAM..." : "Run Deep Clean")
                                .font(.system(size: 13, weight: .bold))
                            Text("Uses your existing purge and cache cleanup flow.")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.55))
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTheme.accent.opacity(0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedTheme.accent.opacity(0.28), lineWidth: 0.6)
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(cleaningInProgress)

                if let cleanStatusMessage {
                    Text(cleanStatusMessage.components(separatedBy: "\n").first ?? cleanStatusMessage)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(cleanStatusIsSuccess ? Color(red: 0.35, green: 0.92, blue: 0.62) : .red.opacity(0.85))
                        .lineLimit(2)
                }
            }
        }
    }

    private var dashboardModulesCard: some View {
        SettingsDashboardCard(
            icon: "menubar.rectangle",
            title: "Menu Bar Modules",
            subtitle: "Choose what stays visible and which module the detail editor controls.",
            badgeText: selectedMenuBarItem.title.uppercased(),
            badgeColor: selectedMenuBarItem.accentColor
        ) {
            VStack(alignment: .leading, spacing: 12) {
                SettingsPrefGroup {
                    ForEach(Array(MenuBarItem.allCases.enumerated()), id: \.element.id) { index, item in
                        MenuBarSettingsSourceRow(
                            item: item,
                            isSelected: selectedMenuBarItem == item,
                            isVisible: preferences.isVisible(item),
                            action: { selectedMenuBarItem = item },
                            toggleAction: { preferences.setVisible($0, for: item) },
                            showDivider: index < MenuBarItem.allCases.count - 1
                        )
                    }
                }

                SettingsPreviewStage {
                    MenuBarPreviewChip(
                        symbolName: selectedMenuBarItem.icon,
                        value: previewValue(for: selectedMenuBarItem),
                        iconSize: preferences.iconSize(for: selectedMenuBarItem),
                        textSize: preferences.textSize(for: selectedMenuBarItem)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var dashboardAlertsCard: some View {
        SettingsDashboardCard(
            icon: "bell.badge",
            title: "Alerts",
            subtitle: "Thresholds stay in sync with the notification engine.",
            badgeText: (preferences.ramAlertEnabled || preferences.cpuAlertEnabled) ? "ARMED" : "OFF",
            badgeColor: Color(red: 1.0, green: 0.64, blue: 0.20)
        ) {
            VStack(alignment: .leading, spacing: 14) {
                SettingsPrefGroup {
                    SettingsPrefRow(
                        "RAM Critical Alert",
                        sublabel: "Warn when usage crosses your selected limit.",
                        showDivider: true
                    ) {
                        HStack(spacing: 8) {
                            ThresholdBadge(
                                text: "\(Int(preferences.ramAlertThreshold))%",
                                color: Color(red: 0.98, green: 0.55, blue: 0.22)
                            )
                            SettingsToggle(
                                isOn: $preferences.ramAlertEnabled,
                                tint: Color(red: 0.98, green: 0.45, blue: 0.09)
                            )
                        }
                    }

                    SettingsSliderRow(
                        label: "RAM Threshold",
                        value: $preferences.ramAlertThreshold,
                        range: 50...95,
                        tint: Color(red: 0.98, green: 0.45, blue: 0.09)
                    )
                }

                SettingsPrefGroup {
                    SettingsPrefRow(
                        "CPU Temperature Alert",
                        sublabel: "Warn when thermals cross your selected limit.",
                        showDivider: true
                    ) {
                        HStack(spacing: 8) {
                            ThresholdBadge(
                                text: preferences.temperatureInFahrenheit
                                    ? "\(Int((preferences.cpuAlertThreshold * 9/5 + 32).rounded()))°F"
                                    : "\(Int(preferences.cpuAlertThreshold))°C",
                                color: Color(red: 0.38, green: 0.65, blue: 1.0)
                            )
                            SettingsToggle(
                                isOn: $preferences.cpuAlertEnabled,
                                tint: Color(red: 0.23, green: 0.51, blue: 0.96)
                            )
                        }
                    }

                    SettingsSliderRow(
                        label: "CPU Threshold",
                        value: $preferences.cpuAlertThreshold,
                        range: 60...100,
                        tint: Color(red: 0.23, green: 0.51, blue: 0.96)
                    )
                }

                Text("Notifications still rely on macOS permission for Therma.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.34))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var dashboardProcessesCard: some View {
        SettingsDashboardCard(
            icon: "list.bullet.rectangle.portrait",
            title: "Top Processes",
            subtitle: "Largest memory consumers from your existing process scanner.",
            badgeText: ramMonitor.isLoadingProcesses ? "SCANNING" : "\(ramMonitor.topProcesses.count) ITEMS",
            badgeColor: pressureColor
        ) {
            if ramMonitor.isLoadingProcesses {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Scanning active processes...")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.vertical, 8)
            } else if ramMonitor.topProcesses.isEmpty {
                Text("No process data is available right now.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.62))
            } else {
                let maxMemory = max(ramMonitor.topProcesses.map(\.memoryMB).max() ?? 1, 1)

                VStack(spacing: 8) {
                    ForEach(Array(ramMonitor.topProcesses.prefix(6).enumerated()), id: \.element.id) { index, process in
                        SettingsProcessUsageRow(
                            process: process,
                            rank: index + 1,
                            maxMemoryMB: maxMemory,
                            tint: selectedTheme.accent
                        )
                    }
                }
            }
        }
    }

    private var dashboardThemeCard: some View {
        SettingsDashboardCard(
            icon: "paintpalette",
            title: "Appearance",
            subtitle: "Keep the window and menu popover visually aligned with the active theme.",
            badgeText: selectedTheme.name.uppercased(),
            badgeColor: selectedTheme.accent
        ) {
            ThemeStripView(
                selectedThemeName: $selectedThemeName,
                statusMessage: nil,
                statusIsSuccess: true
            )
        }
    }

    // MARK: - Menu Bar Pane

    private var menuBarPane: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                SettingsPrefGroup {
                    ForEach(Array(MenuBarItem.allCases.enumerated()), id: \.element.id) { index, item in
                        MenuBarSettingsSourceRow(
                            item: item,
                            isSelected: selectedMenuBarItem == item,
                            isVisible: preferences.isVisible(item),
                            action: { selectedMenuBarItem = item },
                            toggleAction: { preferences.setVisible($0, for: item) },
                            showDivider: index < MenuBarItem.allCases.count - 1
                        )
                    }
                }
            }
            .frame(width: SettingsLayoutMetrics.menuBarSourceListWidth, alignment: .topLeading)

            menuBarDetailPane
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var menuBarDetailPane: some View {
        let item = selectedMenuBarItem

        return VStack(alignment: .leading, spacing: 12) {
            SettingsPreviewStage {
                MenuBarPreviewChip(
                    symbolName: item.icon,
                    value: previewValue(for: item),
                    iconSize: preferences.iconSize(for: item),
                    textSize: preferences.textSize(for: item)
                )
            }

            SettingsPrefGroup {
                SettingsSliderRow(
                    label: "Icon Size",
                    value: iconSizeBinding(for: item),
                    range: Constants.minimumMenuBarIconSize...Constants.maximumMenuBarIconSize,
                    tint: item.accentColor
                )

                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 0.5)
                    .padding(.leading, 14)

                SettingsSliderRow(
                    label: "Text Size",
                    value: textSizeBinding(for: item),
                    range: Constants.minimumMenuBarTextSize...Constants.maximumMenuBarTextSize,
                    tint: item.accentColor
                )
            }
        }
    }

    // MARK: - General Pane

    private var generalPane: some View {
        VStack(spacing: 14) {
            SettingsPrefGroup {
                SettingsPrefRow(
                    "Launch at Login",
                    sublabel: "Start automatically on boot",
                    showDivider: true
                ) {
                    SettingsToggle(
                        isOn: Binding(
                            get: { launchAtLoginManager.isEnabled },
                            set: { launchAtLoginManager.setEnabled($0) }
                        ),
                        tint: Color(red: 0.55, green: 0.36, blue: 0.96)
                    )
                }

                if launchAtLoginManager.requiresApproval {
                    SettingsPrefRow("Requires macOS approval", showDivider: false) {
                        Text("Check System Settings")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.44))
                    }
                } else {
                    SettingsPrefRow("Temperature Unit", showDivider: false) {
                        TemperatureUnitPicker(fahrenheit: $preferences.temperatureInFahrenheit)
                    }
                }
            }

            if launchAtLoginManager.requiresApproval {
                SettingsPrefGroup {
                    SettingsPrefRow("Temperature Unit", showDivider: false) {
                        TemperatureUnitPicker(fahrenheit: $preferences.temperatureInFahrenheit)
                    }
                }
            }
        }
    }

    // MARK: - Alerts Pane

    private var alertsPane: some View {
        VStack(spacing: 14) {
            SettingsPrefGroup {
                SettingsPrefRow(
                    "RAM Critical Alert",
                    sublabel: "Notify when usage exceeds threshold",
                    showDivider: true
                ) {
                    HStack(spacing: 8) {
                        ThresholdBadge(
                            text: "\(Int(preferences.ramAlertThreshold))%",
                            color: Color(red: 0.98, green: 0.55, blue: 0.22)
                        )
                        SettingsToggle(
                            isOn: $preferences.ramAlertEnabled,
                            tint: Color(red: 0.98, green: 0.45, blue: 0.09)
                        )
                    }
                }

                SettingsSliderRow(
                    label: "Threshold",
                    value: $preferences.ramAlertThreshold,
                    range: 50...95,
                    tint: Color(red: 0.98, green: 0.45, blue: 0.09)
                )
            }

            SettingsPrefGroup {
                SettingsPrefRow(
                    "CPU Temperature Alert",
                    sublabel: "Notify when temperature exceeds threshold",
                    showDivider: true
                ) {
                    HStack(spacing: 8) {
                        ThresholdBadge(
                            text: preferences.temperatureInFahrenheit
                                ? "\(Int((preferences.cpuAlertThreshold * 9/5 + 32).rounded()))°F"
                                : "\(Int(preferences.cpuAlertThreshold))°C",
                            color: Color(red: 0.38, green: 0.65, blue: 1.0)
                        )
                        SettingsToggle(
                            isOn: $preferences.cpuAlertEnabled,
                            tint: Color(red: 0.23, green: 0.51, blue: 0.96)
                        )
                    }
                }

                SettingsSliderRow(
                    label: "Threshold",
                    value: $preferences.cpuAlertThreshold,
                    range: 60...100,
                    tint: Color(red: 0.23, green: 0.51, blue: 0.96)
                )
            }

            Text("Alerts use macOS notifications. Ensure Therma is allowed in System Settings.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.28))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - About Pane

    private var aboutPane: some View {
        VStack(spacing: 14) {
            SettingsPrefGroup {
                SettingsPrefRow("Version", showDivider: true) {
                    Text(Constants.appVersion)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                }
                SettingsPrefRow("Platform", showDivider: false) {
                    Text("Apple Silicon · macOS 14+")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }

            SettingsPrefGroup {
                SettingsPrefRow("Software Update", sublabel: updateSubtitle, showDivider: false) {
                    updateControls
                }
            }
        }
    }

    private var updateSubtitle: String {
        switch updateManager.state {
        case .idle:                       return "v\(Constants.appVersion) installed"
        case .checking:                   return "Checking GitHub..."
        case .upToDate:                   return "You're up to date"
        case .available(let version, _):  return "v\(version) available"
        case .downloading:                return "Downloading..."
        case .downloaded(let version, _): return "v\(version) ready to install"
        case .installing:                 return "Installing, relaunching..."
        case .failed(let message):        return message
        }
    }

    @ViewBuilder
    private var updateControls: some View {
        switch updateManager.state {
        case .idle, .failed:
            Button("Check Now") { updateManager.checkForUpdates() }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.25, green: 0.85, blue: 0.62))

        case .checking, .downloading, .installing:
            HStack(spacing: 6) {
                ProgressView().controlSize(.mini).scaleEffect(0.85)
                Text(updateSubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.50))
            }

        case .upToDate:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(red: 0.30, green: 0.88, blue: 0.55))
                    .font(.system(size: 13))
                Button("Check Again") { updateManager.resetToIdle() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.40))
            }

        case .available(let version, let url):
            Button {
                updateManager.startDownload(version: version, downloadURL: url)
            } label: {
                Label("Download v\(version)", systemImage: "arrow.down.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

        case .downloaded(let version, let zipURL):
            Button {
                updateManager.installDownloaded(version: version, zipURL: zipURL)
            } label: {
                Label("Install & Relaunch", systemImage: "arrow.clockwise.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(Color(red: 0.20, green: 0.70, blue: 0.45))
        }
    }

    // MARK: - Helpers

    private var dashboardColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 16), count: 3)
    }

    private var coreTemperatureProgress: Double {
        let temperature = cpuMonitor.currentCelsius ?? cpuMonitor.hottestCelsius ?? 0
        return min(max((temperature - 30) / 70, 0), 1)
    }

    private var batteryTemperatureProgress: Double {
        let temperature = cpuMonitor.batteryCelsius ?? 0
        return min(max((temperature - 25) / 35, 0), 1)
    }

    private var cpuTrendText: String {
        guard let delta = cpuMonitor.trendDelta else { return "STABLE" }
        if abs(delta) < 0.2 { return "STABLE" }
        return preferences.formatCelsiusDelta(delta)
    }

    private var cpuTrendColor: Color {
        guard let delta = cpuMonitor.trendDelta else { return Color(red: 0.60, green: 0.97, blue: 1.0) }
        if abs(delta) < 0.2 { return Color.white.opacity(0.45) }
        return delta > 0
            ? Color(red: 0.60, green: 0.97, blue: 1.0)
            : Color(red: 0.36, green: 0.92, blue: 0.68)
    }

    private var heroStats: [(String, String)] {
        [
            ("Average", cpuMonitor.averageCelsius.map(preferences.formatCelsius) ?? "--"),
            ("Peak", cpuMonitor.hottestCelsius.map(preferences.formatCelsius) ?? "--"),
            ("Sensors", "\(cpuMonitor.sensors.count)")
        ]
    }

    private var heroChartValues: [Double] {
        let history = cpuMonitor.history
        guard !history.isEmpty else { return [38, 40, 39, 48, 37, 61, 45] }
        return history.suffix(12)
    }

    private var networkDownBars: [Double] {
        networkBars(
            seed: systemMetricsMonitor.downloadBytesPerSecond ?? 0,
            baseline: [0.30, 0.62, 1.0, 0.50, 0.76]
        )
    }

    private var networkUpBars: [Double] {
        networkBars(
            seed: systemMetricsMonitor.uploadBytesPerSecond ?? 0,
            baseline: [0.18, 0.28, 0.42, 0.24, 0.34]
        )
    }

    private var pressureColor: Color {
        switch ramMonitor.pressure {
        case .low:
            return Color(red: 0.35, green: 0.92, blue: 0.62)
        case .medium:
            return Color(red: 0.98, green: 0.79, blue: 0.26)
        case .high:
            return Color(red: 1.00, green: 0.40, blue: 0.28)
        }
    }

    private var cpuThermalColor: Color {
        thermalColor(for: cpuMonitor.currentCelsius ?? cpuMonitor.hottestCelsius ?? 0)
    }

    private var batteryThermalColor: Color {
        thermalColor(for: cpuMonitor.batteryCelsius ?? 0)
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

    private func sensorHeatProgress(_ celsius: Double) -> Double {
        min(max((celsius - Constants.cpuNormLow) / Constants.cpuNormRange, 0), 1)
    }

    private func networkBars(seed: Double, baseline: [Double]) -> [Double] {
        guard seed > 0 else { return baseline }
        let normalized = min(max(seed / 12_000_000, 0.18), 1.0)
        return baseline.enumerated().map { index, value in
            let modulation = 0.10 * Double((index % 3) + 1)
            return min(max(value * (0.55 + normalized) + modulation * normalized, 0.16), 1.0)
        }
    }

    private func formattedSwap(_ mb: Double) -> String {
        if mb < 1 { return "0 MB" }
        if mb >= Constants.kbPerMB { return String(format: "%.1f GB", mb / Constants.kbPerMB) }
        return String(format: "%.0f MB", mb)
    }

    private func formatMemory(_ mb: Double) -> String {
        mb >= Constants.kbPerMB
            ? String(format: "%.1f GB", mb / Constants.kbPerMB)
            : String(format: "%.0f MB", mb)
    }

    private func previewValue(for item: MenuBarItem) -> String {
        switch item {
        case .memory:
            return "\(ramMonitor.usagePercent)%"
        case .network:
            return systemMetricsMonitor.networkMenuBarDisplayValue
        case .cpu:
            if let celsius = cpuMonitor.currentCelsius {
                return preferences.formatCelsius(celsius)
            }
            return cpuMonitor.thermalLevel.shortLabel
        case .cpuUsage:
            return systemMetricsMonitor.cpuUsageDisplayValue
        }
    }

    private func performClean() {
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

    private func scheduleCleanTimeout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.cleanTimeoutSeconds) {
            guard self.cleaningInProgress else { return }
            self.cleanTimedOut = true
            self.cleaningInProgress = false
            self.cleanStatusMessage = "Timed out"
            self.cleanStatusIsSuccess = false
            self.scheduleDismissStatus()
        }
    }

    private func scheduleDismissStatus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.statusMessageDismissDelay) {
            self.cleanStatusMessage = nil
        }
    }

    private func closeWindow() {
        if let closeAction { closeAction() } else { dismiss() }
    }

    private func iconSizeBinding(for item: MenuBarItem) -> Binding<Double> {
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

    private func textSizeBinding(for item: MenuBarItem) -> Binding<Double> {
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
