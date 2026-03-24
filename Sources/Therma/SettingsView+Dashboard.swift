import SwiftUI

extension SettingsView {
    var dashboardPane: some View {
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

    func dashboardCardSlot<V: View>(_ view: V, width: CGFloat) -> some View {
        view
            .frame(width: width, height: SettingsLayoutMetrics.dashboardCardHeight, alignment: .topLeading)
            .clipped()
    }

    var dashboardUsageTrendCard: some View {
        SettingsDashboardMockCard(title: "CPU Usage") {
            VStack(spacing: 14) {
                SettingsDashboardValue(
                    value: cpuUsageNumericValue,
                    unit: "%"
                )

                SettingsGlowingAreaChart(values: heroChartValues, tint: selectedTheme.accent)
                    .frame(height: 124)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(height: SettingsLayoutMetrics.dashboardCardHeight, alignment: .top)
    }

    var dashboardMemoryCard: some View {
        SettingsDashboardMockCard(title: "RAM Usage") {
            VStack {
                Spacer(minLength: 0)
                SettingsCircularUsageGauge(
                    progress: Double(ramMonitor.usagePercent) / 100.0,
                    value: "\(ramMonitor.usagePercent)",
                    caption: "%",
                    tint: selectedTheme.accent
                )
                .frame(width: 136, height: 136)
                .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: SettingsLayoutMetrics.dashboardCardHeight, alignment: .top)
    }

    var dashboardCPUCard: some View {
        SettingsDashboardMockCard(title: "CPU Thermal") {
            VStack(spacing: 14) {
                SettingsDashboardValue(
                    value: cpuTemperatureNumericValue,
                    unit: preferences.temperatureInFahrenheit ? "°F" : "°C"
                )

                SettingsGlowingAreaChart(values: cpuMonitor.history, tint: selectedTheme.accent)
                    .frame(height: 124)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(height: SettingsLayoutMetrics.dashboardCardHeight, alignment: .top)
    }

    var dashboardSensorHeatCard: some View {
        SettingsDashboardMockCard(title: "Sensor Heat") {
            VStack(spacing: 18) {
                if cpuMonitor.sensors.isEmpty {
                    Spacer()
                    Text("No readable CPU sensors right now.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                } else {
                    ForEach(Array(cpuMonitor.sensors.prefix(3).enumerated()), id: \.element.id) { _, sensor in
                        SettingsSensorHeatRow(
                            name: compactSensorName(sensor.name),
                            value: preferences.formatCelsius(sensor.celsius),
                            progress: sensorHeatProgress(sensor.celsius),
                            tint: selectedTheme.accent
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: SettingsLayoutMetrics.dashboardCardHeight, alignment: .top)
    }

    var dashboardBatteryCard: some View {
        SettingsDashboardMockCard(title: "Battery Temp") {
            VStack(spacing: 12) {
                SettingsCircularUsageGauge(
                    progress: batteryTemperatureProgress,
                    value: batteryTemperatureNumericValue,
                    caption: preferences.temperatureInFahrenheit ? "°F" : "°C",
                    tint: selectedTheme.accent,
                    valueFontSize: 34,
                    captionFontSize: 10
                )
                .frame(width: 114, height: 114)
                .frame(maxWidth: .infinity)

                batteryCyclesTile

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(height: SettingsLayoutMetrics.dashboardCardHeight, alignment: .top)
    }

    var batteryCyclesTile: some View {
        VStack(spacing: 6) {
            Text("CHARGE CYCLES")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.42))
                .tracking(1.0)

            Text(cpuMonitor.batteryCycleDisplayValue)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(selectedTheme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.6)
                )
        )
    }

    var dashboardActivityCard: some View {
        SettingsDashboardMockCard(title: "Traffic Analysis") {
            VStack(spacing: 22) {
                Spacer(minLength: 0)
                SettingsCompactBarRow(
                    label: "DL",
                    value: systemMetricsMonitor.downloadSpeedDisplayValue,
                    progress: networkDownloadProgress,
                    tint: selectedTheme.accent
                )

                SettingsCompactBarRow(
                    label: "UL",
                    value: systemMetricsMonitor.uploadSpeedDisplayValue,
                    progress: networkUploadProgress,
                    tint: Color(red: 0.25, green: 0.79, blue: 0.64)
                )
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: SettingsLayoutMetrics.dashboardCardHeight, alignment: .top)
    }

    var dashboardQuickActionsCard: some View {
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

    var dashboardModulesCard: some View {
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

    var dashboardAlertsCard: some View {
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
                                tint: selectedTheme.accent
                            )
                        }
                    }

                    SettingsSliderRow(
                        label: "CPU Threshold",
                        value: $preferences.cpuAlertThreshold,
                        range: 60...100,
                        tint: selectedTheme.accent
                    )
                }

                Text("Notifications still rely on macOS permission for Therma.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.34))
            }
        }
        .frame(maxWidth: .infinity)
    }

    var dashboardProcessesCard: some View {
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
}
