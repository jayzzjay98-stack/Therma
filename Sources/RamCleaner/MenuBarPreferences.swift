import Foundation

@Observable
final class MenuBarPreferences {

    // MARK: - Menu Bar Appearance

    var displayMode: MonitorDisplayMode {
        didSet { UserDefaults.standard.set(displayMode.rawValue, forKey: Keys.displayMode) }
    }

    var menuBarIconSize: Double {
        didSet { UserDefaults.standard.set(menuBarIconSize, forKey: Keys.iconSize) }
    }

    var menuBarTextSize: Double {
        didSet { UserDefaults.standard.set(menuBarTextSize, forKey: Keys.textSize) }
    }

    // MARK: - General

    var temperatureInFahrenheit: Bool {
        didSet { UserDefaults.standard.set(temperatureInFahrenheit, forKey: Keys.tempUnit) }
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
        let stored = userDefaults.string(forKey: Keys.displayMode)
        displayMode = MonitorDisplayMode(rawValue: stored ?? "") ?? .memory

        menuBarIconSize = Self.clamp(
            userDefaults.object(forKey: Keys.iconSize) as? Double ?? Constants.defaultMenuBarIconSize,
            min: Constants.minimumMenuBarIconSize, max: Constants.maximumMenuBarIconSize
        )
        menuBarTextSize = Self.clamp(
            userDefaults.object(forKey: Keys.textSize) as? Double ?? Constants.defaultMenuBarTextSize,
            min: Constants.minimumMenuBarTextSize, max: Constants.maximumMenuBarTextSize
        )

        temperatureInFahrenheit = userDefaults.bool(forKey: Keys.tempUnit)
        ramAlertEnabled   = userDefaults.bool(forKey: Keys.ramAlertEnabled)
        ramAlertThreshold = userDefaults.object(forKey: Keys.ramAlertThreshold) as? Double ?? Constants.defaultRamAlertThreshold
        cpuAlertEnabled   = userDefaults.bool(forKey: Keys.cpuAlertEnabled)
        cpuAlertThreshold = userDefaults.object(forKey: Keys.cpuAlertThreshold) as? Double ?? Constants.defaultCpuAlertThreshold
    }

    // MARK: - Reset

    func reset() {
        displayMode           = .memory
        menuBarIconSize       = Constants.defaultMenuBarIconSize
        menuBarTextSize       = Constants.defaultMenuBarTextSize
        temperatureInFahrenheit = false
        ramAlertEnabled       = false
        ramAlertThreshold     = Constants.defaultRamAlertThreshold
        cpuAlertEnabled       = false
        cpuAlertThreshold     = Constants.defaultCpuAlertThreshold
    }

    // MARK: - Temperature formatting

    func formatCelsius(_ celsius: Double) -> String {
        if temperatureInFahrenheit {
            let f = celsius * 9 / 5 + 32
            return "\(Int(f.rounded()))°F"
        }
        return "\(Int(celsius.rounded()))°C"
    }

    /// Formats a temperature delta (e.g. trend ±N°) in the user's preferred unit.
    func formatCelsiusDelta(_ deltaCelsius: Double) -> String {
        let value = temperatureInFahrenheit ? deltaCelsius * 9 / 5 : deltaCelsius
        let unit  = temperatureInFahrenheit ? "°F" : "°C"
        let sign  = deltaCelsius > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))\(unit)"
    }

    // MARK: - Helpers

    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.min(Swift.max(value, min), max)
    }

    private enum Keys {
        static let displayMode       = "monitorDisplayMode"
        static let iconSize          = "menuBarIconSize"
        static let textSize          = "menuBarTextSize"
        static let tempUnit          = "temperatureInFahrenheit"
        static let ramAlertEnabled   = "ramAlertEnabled"
        static let ramAlertThreshold = "ramAlertThreshold"
        static let cpuAlertEnabled   = "cpuAlertEnabled"
        static let cpuAlertThreshold = "cpuAlertThreshold"
    }
}
