import Foundation
import SwiftUI

enum MenuBarItemGroup {
    case memory
    case cpu
}

enum MenuBarItem: String, CaseIterable, Identifiable {
    case memory
    case network
    case cpu
    case cpuUsage

    var id: String { rawValue }

    var group: MenuBarItemGroup {
        switch self {
        case .memory, .network:
            return .memory
        case .cpu, .cpuUsage:
            return .cpu
        }
    }

    var title: String {
        switch self {
        case .memory:   return "RAM"
        case .network:  return "Network"
        case .cpu:      return "CPU"
        case .cpuUsage: return "CPU Usage"
        }
    }

    var icon: String {
        switch self {
        case .memory:   return "cpu"
        case .network:  return "arrow.up.arrow.down"
        case .cpu:      return "thermometer.medium"
        case .cpuUsage: return "gauge.with.dots.needle.50percent"
        }
    }

    var accentColor: Color {
        switch self {
        case .memory, .network:
            return Color(red: 0.23, green: 0.51, blue: 0.96)
        case .cpu:
            return Color(red: 0.98, green: 0.55, blue: 0.22)
        case .cpuUsage:
            return Color(red: 0.99, green: 0.63, blue: 0.18)
        }
    }

    var popoverMode: MonitorDisplayMode {
        group == .memory ? .memory : .cpu
    }

    var previewValue: String {
        switch self {
        case .memory:
            return "68%"
        case .network:
            return "↓1.2M ↑0.4M"
        case .cpu:
            return "54°C"
        case .cpuUsage:
            return "37%"
        }
    }
}

@Observable
final class MenuBarPreferences {

    // MARK: - Legacy Popover Mode

    var displayMode: MonitorDisplayMode {
        didSet { UserDefaults.standard.set(displayMode.rawValue, forKey: Keys.displayMode) }
    }

    // MARK: - Menu Bar Appearance

    var memoryMenuBarVisible: Bool {
        didSet {
            UserDefaults.standard.set(memoryMenuBarVisible, forKey: Keys.memoryVisible)
            syncLegacyDisplayMode()
            notifyStatusBarChange()
        }
    }

    var networkMenuBarVisible: Bool {
        didSet {
            UserDefaults.standard.set(networkMenuBarVisible, forKey: Keys.networkVisible)
            notifyStatusBarChange()
        }
    }

    var cpuMenuBarVisible: Bool {
        didSet {
            UserDefaults.standard.set(cpuMenuBarVisible, forKey: Keys.cpuVisible)
            syncLegacyDisplayMode()
            notifyStatusBarChange()
        }
    }

    var cpuUsageMenuBarVisible: Bool {
        didSet {
            UserDefaults.standard.set(cpuUsageMenuBarVisible, forKey: Keys.cpuUsageVisible)
            notifyStatusBarChange()
        }
    }

    var memoryMenuBarIconSize: Double {
        didSet {
            UserDefaults.standard.set(memoryMenuBarIconSize, forKey: Keys.memoryIconSize)
            notifyStatusBarChange()
        }
    }

    var memoryMenuBarTextSize: Double {
        didSet {
            UserDefaults.standard.set(memoryMenuBarTextSize, forKey: Keys.memoryTextSize)
            notifyStatusBarChange()
        }
    }

    var networkMenuBarIconSize: Double {
        didSet {
            UserDefaults.standard.set(networkMenuBarIconSize, forKey: Keys.networkIconSize)
            notifyStatusBarChange()
        }
    }

    var networkMenuBarTextSize: Double {
        didSet {
            UserDefaults.standard.set(networkMenuBarTextSize, forKey: Keys.networkTextSize)
            notifyStatusBarChange()
        }
    }

    var cpuMenuBarIconSize: Double {
        didSet {
            UserDefaults.standard.set(cpuMenuBarIconSize, forKey: Keys.cpuIconSize)
            notifyStatusBarChange()
        }
    }

    var cpuMenuBarTextSize: Double {
        didSet {
            UserDefaults.standard.set(cpuMenuBarTextSize, forKey: Keys.cpuTextSize)
            notifyStatusBarChange()
        }
    }

    var cpuUsageMenuBarIconSize: Double {
        didSet {
            UserDefaults.standard.set(cpuUsageMenuBarIconSize, forKey: Keys.cpuUsageIconSize)
            notifyStatusBarChange()
        }
    }

    var cpuUsageMenuBarTextSize: Double {
        didSet {
            UserDefaults.standard.set(cpuUsageMenuBarTextSize, forKey: Keys.cpuUsageTextSize)
            notifyStatusBarChange()
        }
    }

    // MARK: - General

    var temperatureInFahrenheit: Bool {
        didSet {
            UserDefaults.standard.set(temperatureInFahrenheit, forKey: Keys.tempUnit)
            notifyStatusBarChange()
        }
    }

    // MARK: - Alerts

    var ramAlertEnabled: Bool {
        didSet { UserDefaults.standard.set(ramAlertEnabled, forKey: Keys.ramAlertEnabled) }
    }

    var ramAlertThreshold: Double {
        didSet { UserDefaults.standard.set(ramAlertThreshold, forKey: Keys.ramAlertThreshold) }
    }

    var cpuAlertEnabled: Bool {
        didSet { UserDefaults.standard.set(cpuAlertEnabled, forKey: Keys.cpuAlertEnabled) }
    }

    var cpuAlertThreshold: Double {
        didSet { UserDefaults.standard.set(cpuAlertThreshold, forKey: Keys.cpuAlertThreshold) }
    }

    // MARK: - Init

    init(userDefaults: UserDefaults = .standard) {
        let storedMode = userDefaults.string(forKey: Keys.displayMode)
        let legacyDisplayMode = MonitorDisplayMode(rawValue: storedMode ?? "") ?? .memory
        displayMode = legacyDisplayMode

        let legacyIconSize = userDefaults.object(forKey: Keys.iconSize) as? Double ?? Constants.defaultMenuBarIconSize
        let legacyTextSize = userDefaults.object(forKey: Keys.textSize) as? Double ?? Constants.defaultMenuBarTextSize
        let memoryBaseIconSize = Self.clamp(
            userDefaults.object(forKey: Keys.memoryIconSize) as? Double ?? legacyIconSize,
            min: Constants.minimumMenuBarIconSize,
            max: Constants.maximumMenuBarIconSize
        )
        let memoryBaseTextSize = Self.clamp(
            userDefaults.object(forKey: Keys.memoryTextSize) as? Double ?? legacyTextSize,
            min: Constants.minimumMenuBarTextSize,
            max: Constants.maximumMenuBarTextSize
        )
        let cpuBaseIconSize = Self.clamp(
            userDefaults.object(forKey: Keys.cpuIconSize) as? Double ?? legacyIconSize,
            min: Constants.minimumMenuBarIconSize,
            max: Constants.maximumMenuBarIconSize
        )
        let cpuBaseTextSize = Self.clamp(
            userDefaults.object(forKey: Keys.cpuTextSize) as? Double ?? legacyTextSize,
            min: Constants.minimumMenuBarTextSize,
            max: Constants.maximumMenuBarTextSize
        )

        memoryMenuBarVisible = userDefaults.object(forKey: Keys.memoryVisible) as? Bool ?? legacyDisplayMode.showsMemory
        cpuMenuBarVisible = userDefaults.object(forKey: Keys.cpuVisible) as? Bool ?? legacyDisplayMode.showsCPU
        networkMenuBarVisible = userDefaults.object(forKey: Keys.networkVisible) as? Bool
            ?? userDefaults.object(forKey: Keys.legacyNetworkVisible) as? Bool
            ?? true
        cpuUsageMenuBarVisible = userDefaults.object(forKey: Keys.cpuUsageVisible) as? Bool
            ?? userDefaults.object(forKey: Keys.legacyCPUUsageVisible) as? Bool
            ?? true

        memoryMenuBarIconSize = memoryBaseIconSize
        memoryMenuBarTextSize = memoryBaseTextSize
        networkMenuBarIconSize = Self.clamp(
            userDefaults.object(forKey: Keys.networkIconSize) as? Double ?? memoryBaseIconSize,
            min: Constants.minimumMenuBarIconSize,
            max: Constants.maximumMenuBarIconSize
        )
        networkMenuBarTextSize = Self.clamp(
            userDefaults.object(forKey: Keys.networkTextSize) as? Double ?? memoryBaseTextSize,
            min: Constants.minimumMenuBarTextSize,
            max: Constants.maximumMenuBarTextSize
        )
        cpuMenuBarIconSize = cpuBaseIconSize
        cpuMenuBarTextSize = cpuBaseTextSize
        cpuUsageMenuBarIconSize = Self.clamp(
            userDefaults.object(forKey: Keys.cpuUsageIconSize) as? Double ?? cpuBaseIconSize,
            min: Constants.minimumMenuBarIconSize,
            max: Constants.maximumMenuBarIconSize
        )
        cpuUsageMenuBarTextSize = Self.clamp(
            userDefaults.object(forKey: Keys.cpuUsageTextSize) as? Double ?? cpuBaseTextSize,
            min: Constants.minimumMenuBarTextSize,
            max: Constants.maximumMenuBarTextSize
        )

        temperatureInFahrenheit = userDefaults.bool(forKey: Keys.tempUnit)
        ramAlertEnabled = userDefaults.bool(forKey: Keys.ramAlertEnabled)
        ramAlertThreshold = userDefaults.object(forKey: Keys.ramAlertThreshold) as? Double ?? Constants.defaultRamAlertThreshold
        cpuAlertEnabled = userDefaults.bool(forKey: Keys.cpuAlertEnabled)
        cpuAlertThreshold = userDefaults.object(forKey: Keys.cpuAlertThreshold) as? Double ?? Constants.defaultCpuAlertThreshold

        syncLegacyDisplayMode()
    }

    // MARK: - Reset

    func reset() {
        memoryMenuBarVisible = true
        networkMenuBarVisible = true
        cpuMenuBarVisible = true
        cpuUsageMenuBarVisible = true

        memoryMenuBarIconSize = Constants.defaultMenuBarIconSize
        memoryMenuBarTextSize = Constants.defaultMenuBarTextSize
        networkMenuBarIconSize = Constants.defaultMenuBarIconSize
        networkMenuBarTextSize = Constants.defaultMenuBarTextSize
        cpuMenuBarIconSize = Constants.defaultMenuBarIconSize
        cpuMenuBarTextSize = Constants.defaultMenuBarTextSize
        cpuUsageMenuBarIconSize = Constants.defaultMenuBarIconSize
        cpuUsageMenuBarTextSize = Constants.defaultMenuBarTextSize

        temperatureInFahrenheit = false
        ramAlertEnabled = false
        ramAlertThreshold = Constants.defaultRamAlertThreshold
        cpuAlertEnabled = false
        cpuAlertThreshold = Constants.defaultCpuAlertThreshold

        syncLegacyDisplayMode()
    }

    // MARK: - Temperature formatting

    func formatCelsius(_ celsius: Double) -> String {
        if temperatureInFahrenheit {
            let f = celsius * 9 / 5 + 32
            return "\(Int(f.rounded()))°F"
        }
        return "\(Int(celsius.rounded()))°C"
    }

    func formatCelsiusDelta(_ deltaCelsius: Double) -> String {
        let value = temperatureInFahrenheit ? deltaCelsius * 9 / 5 : deltaCelsius
        let unit = temperatureInFahrenheit ? "°F" : "°C"
        let sign = deltaCelsius > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))\(unit)"
    }

    // MARK: - Helpers

    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.min(Swift.max(value, min), max)
    }

    private func notifyStatusBarChange() {
        NotificationCenter.default.post(name: .thermaStatusBarDidChange, object: nil)
    }

    var visibleItems: [MenuBarItem] {
        MenuBarItem.allCases.filter(isVisible)
    }

    func isVisible(_ item: MenuBarItem) -> Bool {
        switch item {
        case .memory:
            return memoryMenuBarVisible
        case .network:
            return networkMenuBarVisible
        case .cpu:
            return cpuMenuBarVisible
        case .cpuUsage:
            return cpuUsageMenuBarVisible
        }
    }

    func setVisible(_ visible: Bool, for item: MenuBarItem) {
        if !visible, isVisible(item), visibleItems.count == 1 {
            return
        }

        switch item {
        case .memory:
            memoryMenuBarVisible = visible
        case .network:
            networkMenuBarVisible = visible
        case .cpu:
            cpuMenuBarVisible = visible
        case .cpuUsage:
            cpuUsageMenuBarVisible = visible
        }
    }

    func iconSize(for item: MenuBarItem) -> Double {
        switch item {
        case .memory:
            return memoryMenuBarIconSize
        case .network:
            return networkMenuBarIconSize
        case .cpu:
            return cpuMenuBarIconSize
        case .cpuUsage:
            return cpuUsageMenuBarIconSize
        }
    }

    func textSize(for item: MenuBarItem) -> Double {
        switch item {
        case .memory:
            return memoryMenuBarTextSize
        case .network:
            return networkMenuBarTextSize
        case .cpu:
            return cpuMenuBarTextSize
        case .cpuUsage:
            return cpuUsageMenuBarTextSize
        }
    }

    private func syncLegacyDisplayMode() {
        switch (memoryMenuBarVisible, cpuMenuBarVisible) {
        case (true, true):
            displayMode = .both
        case (true, false):
            displayMode = .memory
        case (false, true):
            displayMode = .cpu
        case (false, false):
            displayMode = .memory
        }
    }

    private enum Keys {
        static let displayMode = "monitorDisplayMode"

        static let memoryVisible = "memoryMenuBarVisible"
        static let networkVisible = "networkMenuBarVisible"
        static let cpuVisible = "cpuMenuBarVisible"
        static let cpuUsageVisible = "cpuUsageMenuBarVisible"

        static let memoryIconSize = "memoryMenuBarIconSize"
        static let memoryTextSize = "memoryMenuBarTextSize"
        static let networkIconSize = "networkMenuBarIconSize"
        static let networkTextSize = "networkMenuBarTextSize"
        static let cpuIconSize = "cpuMenuBarIconSize"
        static let cpuTextSize = "cpuMenuBarTextSize"
        static let cpuUsageIconSize = "cpuUsageMenuBarIconSize"
        static let cpuUsageTextSize = "cpuUsageMenuBarTextSize"

        static let legacyCPUUsageVisible = "showCPUUsageInPopover"
        static let legacyNetworkVisible = "showNetworkSpeedInPopover"

        static let iconSize = "menuBarIconSize"
        static let textSize = "menuBarTextSize"
        static let tempUnit = "temperatureInFahrenheit"
        static let ramAlertEnabled = "ramAlertEnabled"
        static let ramAlertThreshold = "ramAlertThreshold"
        static let cpuAlertEnabled = "cpuAlertEnabled"
        static let cpuAlertThreshold = "cpuAlertThreshold"
    }
}
