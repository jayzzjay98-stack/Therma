import SwiftUI

extension SettingsView {
    var menuBarPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsPaneHero(
                icon: "menubar.rectangle",
                title: "Menu Bar Control",
                subtitle: "Select a module to preview it, then tune icon and text sizing without affecting visibility.",
                pills: [selectedMenuBarItem.title, preferences.isVisible(selectedMenuBarItem) ? "Visible" : "Hidden"]
            )
            .frame(height: SettingsLayoutMetrics.paneHeroHeight)

            HStack(alignment: .top, spacing: 16) {
                SettingsPanelCard(
                    title: "Modules",
                    subtitle: "Choose which item you want to edit. The switch only controls whether it is shown in the menu bar.",
                    centeredHeader: true
                ) {
                    VStack(spacing: 8) {
                        ForEach(MenuBarItem.allCases, id: \.id) { item in
                            SettingsSourceToggleRow(
                                icon: item.icon,
                                label: item.title,
                                subtitle: preferences.isVisible(item) ? "Shown in menu bar" : "Hidden from menu bar",
                                isOn: preferences.isVisible(item),
                                isSelected: selectedMenuBarItem == item,
                                selectAction: { selectedMenuBarItem = item },
                                toggleAction: { preferences.setVisible(!preferences.isVisible(item), for: item) }
                            )
                        }
                    }
                }
                .frame(width: SettingsLayoutMetrics.menuBarModulePanelWidth, alignment: .topLeading)

                menuBarDetailPane
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    var menuBarDetailPane: some View {
        let item = selectedMenuBarItem

        return VStack(alignment: .leading, spacing: 16) {
            SettingsPanelCard(
                title: "\(item.title) Preview",
                subtitle: "This preview reflects the selected module and its current size settings.",
                centeredHeader: true
            ) {
                SettingsPreviewStage {
                    MenuBarPreviewChip(
                        symbolName: item.icon,
                        value: previewValue(for: item),
                        iconSize: preferences.iconSize(for: item),
                        textSize: preferences.textSize(for: item)
                    )
                }
            }

            SettingsPanelCard(
                title: "Sizing Controls",
                subtitle: "Fine tune how this module reads in the menu bar.",
                centeredHeader: true
            ) {
                SettingsPrefGroup {
                    SettingsSliderRow(
                        label: "Icon Size",
                        value: iconSizeBinding(for: item),
                        range: Constants.minimumMenuBarIconSize...Constants.maximumMenuBarIconSize,
                        tint: selectedTheme.accent
                    )

                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 0.5)
                        .padding(.leading, 14)

                    SettingsSliderRow(
                        label: "Text Size",
                        value: textSizeBinding(for: item),
                        range: Constants.minimumMenuBarTextSize...Constants.maximumMenuBarTextSize,
                        tint: selectedTheme.accent
                    )
                }
            }

            if item == .network {
                SettingsPanelCard(
                    title: "Network Display",
                    subtitle: "Choose which network metrics to display in the menu bar.",
                    centeredHeader: true
                ) {
                    SettingsPrefGroup {
                        SettingsPrefRow("Show Download Speed", sublabel: "Display incoming network traffic amount", showDivider: true) {
                            SettingsToggle(isOn: $preferences.networkShowDownload, tint: selectedTheme.accent)
                        }
                        SettingsPrefRow("Show Upload Speed", sublabel: "Display outgoing network traffic amount", showDivider: false) {
                            SettingsToggle(isOn: $preferences.networkShowUpload, tint: selectedTheme.accent)
                        }
                    }
                }
            }
        }
    }

    var generalPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsPaneHero(
                icon: "gearshape",
                title: "General Preferences",
                subtitle: "Core app behavior, startup preferences, and default display choices for Therma.",
                pills: [launchAtLoginManager.isEnabled ? "Launch at Login" : "Manual Start", preferences.temperatureInFahrenheit ? "Fahrenheit" : "Celsius"]
            )
            .frame(height: SettingsLayoutMetrics.paneHeroHeight)

            HStack(alignment: .top, spacing: 16) {
                SettingsPanelCard(
                    title: "Startup",
                    subtitle: "Control how Therma behaves when your Mac signs in.",
                    centeredHeader: true
                ) {
                    SettingsPrefGroup {
                        SettingsPrefRow(
                            "Launch at Login",
                            sublabel: "Automatically start Therma when you log in",
                            showDivider: launchAtLoginManager.requiresApproval
                        ) {
                            SettingsToggle(
                                isOn: Binding(
                                    get: { launchAtLoginManager.isEnabled },
                                    set: { launchAtLoginManager.setEnabled($0) }
                                ),
                                tint: selectedTheme.accent
                            )
                        }

                        if launchAtLoginManager.requiresApproval {
                            SettingsPrefRow(
                                "Requires macOS approval",
                                sublabel: "System Settings must authorize Therma before launch at login is available.",
                                showDivider: false
                            ) {
                                Text("Pending")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.44))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: 16) {
                    SettingsPanelCard(
                        title: "Display Defaults",
                        subtitle: "Choose the default temperature scale used across the app.",
                        centeredHeader: true
                    ) {
                        HStack(spacing: 12) {
                            TemperatureUnitPicker(fahrenheit: $preferences.temperatureInFahrenheit)
                            Spacer(minLength: 0)
                        }
                    }

                    HStack(spacing: 12) {
                        SettingsMiniStatCard(label: "Startup", value: launchAtLoginManager.isEnabled ? "ON" : "OFF")
                        SettingsMiniStatCard(label: "Unit", value: preferences.temperatureInFahrenheit ? "°F" : "°C")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity)
    }

    var alertsPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsPaneHero(
                icon: "bell.badge",
                title: "Alert Center",
                subtitle: "Configure proactive notifications for memory pressure and CPU temperature thresholds.",
                pills: [preferences.ramAlertEnabled ? "RAM Armed" : "RAM Off", preferences.cpuAlertEnabled ? "CPU Armed" : "CPU Off"]
            )
            .frame(height: SettingsLayoutMetrics.paneHeroHeight)

            HStack(alignment: .top, spacing: 16) {
                SettingsAlertBlock(
                    title: "RAM Critical Alert",
                    isOn: preferences.ramAlertEnabled,
                    toggleAction: { preferences.ramAlertEnabled.toggle() },
                    footer: "Alert when RAM usage exceeds this threshold (50% - 95%)"
                ) {
                    SettingsSliderRow(
                        label: "Threshold",
                        value: $preferences.ramAlertThreshold,
                        range: 50...95,
                        tint: selectedTheme.accent
                    )
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                SettingsAlertBlock(
                    title: "CPU Temperature Alert",
                    isOn: preferences.cpuAlertEnabled,
                    toggleAction: { preferences.cpuAlertEnabled.toggle() },
                    footer: "Alert when CPU temperature exceeds this threshold (60°C - \(Int(Constants.cpuNormHigh))°C)"
                ) {
                    SettingsSliderRow(
                        label: "Threshold",
                        value: $preferences.cpuAlertThreshold,
                        range: 60...100,
                        tint: selectedTheme.accent
                    )
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
