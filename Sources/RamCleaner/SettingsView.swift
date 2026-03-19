import SwiftUI

// MARK: - Settings Tab

enum SettingsTab: String, CaseIterable, Identifiable {
    case menuBar = "Menu Bar"
    case general = "General"
    case alerts  = "Alerts"
    case about   = "About"

    var id: String { rawValue }

    var title: String { rawValue }

    var icon: String {
        switch self {
        case .menuBar: return "menubar.rectangle"
        case .general: return "gearshape"
        case .alerts:  return "bell"
        case .about:   return "info.circle"
        }
    }

    var accentColor: Color {
        switch self {
        case .menuBar: return Color(red: 0.23, green: 0.51, blue: 0.96)
        case .general: return Color(red: 0.55, green: 0.36, blue: 0.96)
        case .alerts:  return Color(red: 0.98, green: 0.45, blue: 0.09)
        case .about:   return Color(red: 0.06, green: 0.73, blue: 0.51)
        }
    }

    var iconGradient: LinearGradient {
        switch self {
        case .menuBar:
            return LinearGradient(colors: [Color(red: 0.35, green: 0.57, blue: 1.0),
                                           Color(red: 0.15, green: 0.38, blue: 0.90)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .general:
            return LinearGradient(colors: [Color(red: 0.66, green: 0.48, blue: 1.0),
                                           Color(red: 0.46, green: 0.26, blue: 0.88)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .alerts:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.56, blue: 0.22),
                                           Color(red: 0.90, green: 0.33, blue: 0.05)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .about:
            return LinearGradient(colors: [Color(red: 0.25, green: 0.85, blue: 0.62),
                                           Color(red: 0.04, green: 0.60, blue: 0.40)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var preferences: MenuBarPreferences
    @ObservedObject var updateManager: UpdateManager
    let closeAction: (() -> Void)?

    @State private var selectedTab: SettingsTab = .menuBar
    @State private var launchAtLoginManager = LaunchAtLoginManager()

    init(
        preferences: MenuBarPreferences,
        updateManager: UpdateManager,
        closeAction: (() -> Void)? = nil
    ) {
        self.preferences = preferences
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
        .onAppear { launchAtLoginManager.refresh() }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(SettingsTab.allCases) { tab in
                SettingsSidebarItem(tab: tab, isSelected: selectedTab == tab) {
                    selectedTab = tab
                }
            }
            Spacer()
        }
        .padding(10)
        .frame(width: SettingsLayoutMetrics.sidebarWidth)
        .background(
            Color.black.opacity(0.28)
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 0.5)
                }
        )
    }

    // MARK: - Content Panel

    private var contentPanel: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text(selectedTab.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                switch selectedTab {
                case .menuBar: menuBarPane
                case .general: generalPane
                case .alerts:  alertsPane
                case .about:   aboutPane
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Menu Bar Pane

    private var menuBarPane: some View {
        VStack(spacing: 14) {
            // Live preview
            HStack(spacing: 12) {
                if preferences.displayMode != .cpu {
                    MenuBarPreviewChip(displayMode: .memory,
                                      iconSize: preferences.menuBarIconSize,
                                      textSize: preferences.menuBarTextSize,
                                      cpuValue: preferences.formatCelsius(54))
                }
                if preferences.displayMode != .memory {
                    MenuBarPreviewChip(displayMode: .cpu,
                                      iconSize: preferences.menuBarIconSize,
                                      textSize: preferences.menuBarTextSize,
                                      cpuValue: preferences.formatCelsius(54))
                }
                if preferences.displayMode == .memory {
                    MenuBarPreviewChip(displayMode: .memory,
                                      iconSize: preferences.menuBarIconSize,
                                      textSize: preferences.menuBarTextSize,
                                      cpuValue: preferences.formatCelsius(54))
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
            )

            // Display mode
            SettingsPrefGroup {
                SettingsPrefRow("Display", sublabel: "Visible items in menu bar", showDivider: false) {
                    SettingsModePicker(selection: $preferences.displayMode)
                        .frame(width: SettingsLayoutMetrics.modePickerWidth)
                }
            }

            // Sizes
            SettingsPrefGroup {
                SettingsSliderRow(
                    label: "Icon Size",
                    value: $preferences.menuBarIconSize,
                    range: Constants.minimumMenuBarIconSize...Constants.maximumMenuBarIconSize,
                    tint: Color(red: 0.23, green: 0.51, blue: 0.96)
                )
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 0.5)
                    .padding(.leading, 14)
                SettingsSliderRow(
                    label: "Text Size",
                    value: $preferences.menuBarTextSize,
                    range: Constants.minimumMenuBarTextSize...Constants.maximumMenuBarTextSize,
                    tint: Color(red: 0.23, green: 0.51, blue: 0.96)
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

            if !launchAtLoginManager.requiresApproval {
                EmptyView()
            } else {
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
            // RAM Alert
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

            // CPU Alert
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

            Text("Alerts use macOS notifications — ensure notifications are enabled for Therma in System Settings.")
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
        case .checking:                   return "Checking GitHub…"
        case .upToDate:                   return "You're up to date"
        case .available(let v, _):        return "v\(v) available"
        case .downloading:                return "Downloading…"
        case .downloaded(let v, _):       return "v\(v) ready to install"
        case .installing:                 return "Installing, relaunching…"
        case .failed(let msg):            return msg
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

    private func closeWindow() {
        if let closeAction { closeAction() } else { dismiss() }
    }
}
