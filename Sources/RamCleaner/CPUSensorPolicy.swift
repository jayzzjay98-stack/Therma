import Foundation

struct CPUSnapshotBuilder {
    let thermalPolicy: CPUSensorThermalPolicy

    init(thermalPolicy: CPUSensorThermalPolicy = CPUSensorThermalPolicy()) {
        self.thermalPolicy = thermalPolicy
    }

    func buildSnapshot(
        readings: [CPUTemperatureSensor],
        batteryCycleCount: Int?
    ) -> CPUSnapshot {
        let batteryReading = selectBatteryReading(from: readings)
        let sensors = selectCPUSensors(from: readings)

        guard !sensors.isEmpty else {
            return CPUSnapshot(
                currentCelsius: nil,
                averageCelsius: nil,
                hottestCelsius: nil,
                hottestSensorName: nil,
                batteryCelsius: batteryReading?.celsius,
                batterySensorName: batteryReading?.name,
                batteryCycleCount: batteryCycleCount,
                thermalLevel: thermalPolicy.fallbackLevel(for: ProcessInfo.processInfo.thermalState),
                sourceName: "macOS Thermal State",
                lastUpdated: Date(),
                sensors: []
            )
        }

        let hottest = sensors[0]
        let average = sensors.map(\.celsius).reduce(0, +) / Double(sensors.count)

        return CPUSnapshot(
            currentCelsius: hottest.celsius,
            averageCelsius: average,
            hottestCelsius: hottest.celsius,
            hottestSensorName: hottest.name,
            batteryCelsius: batteryReading?.celsius,
            batterySensorName: batteryReading?.name,
            batteryCycleCount: batteryCycleCount,
            thermalLevel: thermalPolicy.classify(hottest.celsius),
            sourceName: "Apple HID Sensors",
            lastUpdated: Date(),
            sensors: Array(sensors.prefix(Constants.cpuVisibleSensorCount))
        )
    }

    private func selectBatteryReading(from readings: [CPUTemperatureSensor]) -> CPUTemperatureSensor? {
        readings
            .filter { CPUSensorPolicy.isLikelyBatterySensor(named: $0.name, celsius: $0.celsius) }
            .max(by: { $0.celsius < $1.celsius })
    }

    private func selectCPUSensors(from readings: [CPUTemperatureSensor]) -> [CPUTemperatureSensor] {
        let cpuReadings = readings.filter {
            CPUSensorPolicy.isLikelyCPUSensor(named: $0.name, celsius: $0.celsius)
        }
        let selectedReadings = cpuReadings.isEmpty
            ? readings.filter {
                CPUSensorPolicy.isFallbackSensor(named: $0.name, celsius: $0.celsius)
            }
            : cpuReadings

        return selectedReadings.sorted { $0.celsius > $1.celsius }
    }
}

struct CPUSensorThermalPolicy {
    func classify(_ celsius: Double) -> CPUThermalLevel {
        switch celsius {
        case ..<Constants.cpuWarmThreshold:
            return .nominal
        case ..<Constants.cpuHotThreshold:
            return .fair
        case ..<Constants.cpuCriticalThreshold:
            return .serious
        default:
            return .critical
        }
    }

    func fallbackLevel(for state: ProcessInfo.ThermalState) -> CPUThermalLevel {
        switch state {
        case .nominal:  return .nominal
        case .fair:     return .fair
        case .serious:  return .serious
        case .critical: return .critical
        @unknown default:
            return .fair
        }
    }
}

enum CPUSensorPolicy {
    static func isLikelyCPUSensor(named name: String, celsius: Double) -> Bool {
        guard isPlausibleTemperature(celsius) else { return false }

        let normalized = name.lowercased()
        if isLikelyBatterySensor(named: name, celsius: celsius) || normalized.contains("nand") {
            return false
        }

        return normalized.contains("tdie") || normalized.contains("cpu")
    }

    static func isLikelyBatterySensor(named name: String, celsius: Double) -> Bool {
        guard isPlausibleTemperature(celsius) else { return false }

        let normalized = name.lowercased()
        return normalized.contains("battery")
            || normalized.contains("gas gauge")
            || normalized.contains("batt")
    }

    static func isFallbackSensor(named name: String, celsius: Double) -> Bool {
        guard isPlausibleTemperature(celsius) else { return false }
        let normalized = name.lowercased()
        return !isLikelyBatterySensor(named: name, celsius: celsius) && !normalized.contains("nand")
    }

    static func isPlausibleTemperature(_ celsius: Double) -> Bool {
        celsius.isFinite
            && celsius >= Constants.cpuMinimumPlausibleTemperature
            && celsius <= Constants.cpuMaximumPlausibleTemperature
    }
}
