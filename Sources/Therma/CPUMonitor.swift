import Foundation
import IOKit
import IOKit.hidsystem

enum CPUThermalLevel: String {
    case nominal = "Nominal"
    case fair = "Warm"
    case serious = "Hot"
    case critical = "Critical"

    var shortLabel: String {
        switch self {
        case .nominal:  return "COOL"
        case .fair:     return "WARM"
        case .serious:  return "HOT"
        case .critical: return "CRIT"
        }
    }

    var isWarning: Bool {
        self == .serious || self == .critical
    }
}

struct CPUTemperatureSensor: Identifiable {
    let id: String
    let name: String
    let celsius: Double
}

struct CPUSnapshot {
    let currentCelsius: Double?
    let averageCelsius: Double?
    let hottestCelsius: Double?
    let hottestSensorName: String?
    let batteryCelsius: Double?
    let batterySensorName: String?
    let batteryCycleCount: Int?
    let thermalLevel: CPUThermalLevel
    let sourceName: String
    let lastUpdated: Date
    let sensors: [CPUTemperatureSensor]
}

private enum HIDTemperatureBridge {
    static let temperatureEventType: Int64 = 15
    static let temperatureField: Int32 = 15 << 16
    static let matching: [String: Int] = [
        "PrimaryUsagePage": 0xff00,
        "PrimaryUsage": 0x5
    ]

    @_silgen_name("IOHIDEventSystemClientCreate")
    static func createClient(_ allocator: CFAllocator?) -> OpaquePointer?

    @_silgen_name("IOHIDEventSystemClientSetMatching")
    static func setMatching(_ client: OpaquePointer?, _ matching: CFDictionary?) -> Int32

    @_silgen_name("IOHIDServiceClientCopyEvent")
    static func copyEvent(
        _ service: IOHIDServiceClient,
        _ type: Int64,
        _ options: Int32,
        _ timestamp: Int64
    ) -> OpaquePointer?

    @_silgen_name("IOHIDEventGetFloatValue")
    static func getFloatValue(_ event: OpaquePointer?, _ field: Int32) -> Double
}

final class CPUSensorProvider {
    private let snapshotBuilder: CPUSnapshotBuilder
    private var cachedBatteryCycleCount: Int?
    private var cycleCountRead = false

    init(snapshotBuilder: CPUSnapshotBuilder = CPUSnapshotBuilder()) {
        self.snapshotBuilder = snapshotBuilder
    }

    func fetchSnapshot() -> CPUSnapshot {
        let rawReadings = readSensors()
        if !cycleCountRead {
            cachedBatteryCycleCount = readBatteryCycleCount()
            cycleCountRead = true
        }
        return snapshotBuilder.buildSnapshot(
            readings: rawReadings,
            batteryCycleCount: cachedBatteryCycleCount
        )
    }

    private func readSensors() -> [CPUTemperatureSensor] {
        guard let rawClient = HIDTemperatureBridge.createClient(kCFAllocatorDefault) else { return [] }
        _ = HIDTemperatureBridge.setMatching(rawClient, HIDTemperatureBridge.matching as CFDictionary)

        let client = unsafeBitCast(rawClient, to: IOHIDEventSystemClient.self)
        let services = IOHIDEventSystemClientCopyServices(client) as? [IOHIDServiceClient] ?? []

        return services.compactMap(reading(for:))
    }

    private func reading(for service: IOHIDServiceClient) -> CPUTemperatureSensor? {
        let name = (
            IOHIDServiceClientCopyProperty(service, "Product" as CFString) as? String ??
            IOHIDServiceClientCopyProperty(service, "Name" as CFString) as? String ??
            "Unknown Sensor"
        )

        guard let event = HIDTemperatureBridge.copyEvent(
            service,
            HIDTemperatureBridge.temperatureEventType,
            0,
            0
        ) else { return nil }

        let celsius = HIDTemperatureBridge.getFloatValue(event, HIDTemperatureBridge.temperatureField)
        guard Self.isPlausibleTemperature(celsius) else { return nil }

        return CPUTemperatureSensor(id: name, name: name, celsius: celsius)
    }

    private func readBatteryCycleCount() -> Int? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        if let cycleCount = IORegistryEntryCreateCFProperty(
            service,
            "CycleCount" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() {
            return Self.parseBatteryCycleCount(cycleCount)
        }

        return nil
    }

    static func isLikelyCPUSensor(named name: String, celsius: Double) -> Bool {
        CPUSensorPolicy.isLikelyCPUSensor(named: name, celsius: celsius)
    }

    static func isLikelyBatterySensor(named name: String, celsius: Double) -> Bool {
        CPUSensorPolicy.isLikelyBatterySensor(named: name, celsius: celsius)
    }

    static func isFallbackSensor(named name: String, celsius: Double) -> Bool {
        CPUSensorPolicy.isFallbackSensor(named: name, celsius: celsius)
    }

    static func isPlausibleTemperature(_ celsius: Double) -> Bool {
        CPUSensorPolicy.isPlausibleTemperature(celsius)
    }

    static func parseBatteryCycleCount(_ rawValue: Any) -> Int? {
        if let value = rawValue as? Int {
            return value
        }

        if let value = rawValue as? NSNumber {
            return value.intValue
        }

        if let value = rawValue as? String {
            return Int(value)
        }

        return nil
    }
}

@Observable
final class CPUMonitor {
    var currentCelsius: Double?
    var averageCelsius: Double?
    var hottestCelsius: Double?
    var hottestSensorName: String?
    var batteryCelsius: Double?
    var batterySensorName: String?
    var batteryCycleCount: Int?
    var thermalLevel: CPUThermalLevel = .nominal
    var sourceName: String = "macOS Thermal State"
    var lastUpdated: Date = .distantPast
    var lastError: String?
    var sensors: [CPUTemperatureSensor] = []
    var history: [Double] = []

    private let provider: CPUSensorProvider
    private let autoRefresh: Bool
    private var refreshTimer: Timer?

    init(provider: CPUSensorProvider = CPUSensorProvider(), autoRefresh: Bool = true) {
        self.provider = provider
        self.autoRefresh = autoRefresh
        refresh()
        if autoRefresh {
            startTimer()
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }

    var displayValue: String {
        if let currentCelsius {
            return "\(Int(currentCelsius.rounded()))C"
        }
        return thermalLevel.shortLabel
    }

    var averageDisplayValue: String {
        guard let averageCelsius else { return "--" }
        return "\(Int(averageCelsius.rounded()))C"
    }

    var peakDisplayValue: String {
        guard let hottestCelsius else { return "--" }
        return "\(Int(hottestCelsius.rounded()))C"
    }

    var batteryDisplayValue: String {
        guard let batteryCelsius else { return "--" }
        return "\(Int(batteryCelsius.rounded()))C"
    }

    var batteryCycleDisplayValue: String {
        guard let batteryCycleCount else { return "-- CYCLES" }
        return "\(batteryCycleCount) CYCLES"
    }

    var trendDelta: Double? {
        guard history.count >= 2 else { return nil }
        return history[history.count - 1] - history[history.count - 2]
    }

    func refresh() {
        let snapshot = provider.fetchSnapshot()
        apply(snapshot)
        appendHistoryValue(snapshot.currentCelsius)
    }

    private func apply(_ snapshot: CPUSnapshot) {
        currentCelsius = snapshot.currentCelsius
        averageCelsius = snapshot.averageCelsius
        hottestCelsius = snapshot.hottestCelsius
        hottestSensorName = snapshot.hottestSensorName
        batteryCelsius = snapshot.batteryCelsius
        batterySensorName = snapshot.batterySensorName
        batteryCycleCount = snapshot.batteryCycleCount
        thermalLevel = snapshot.thermalLevel
        sourceName = snapshot.sourceName
        lastUpdated = snapshot.lastUpdated
        sensors = snapshot.sensors
        lastError = nil
    }

    private func appendHistoryValue(_ value: Double?) {
        guard let value else { return }
        history.append(value)
        if history.count > Constants.cpuHistorySampleCount {
            history.removeFirst(history.count - Constants.cpuHistorySampleCount)
        }
    }

    private func startTimer() {
        let start: () -> Void = { [weak self] in
            guard let self else { return }
            self.refreshTimer?.invalidate()
            self.refreshTimer = Timer.scheduledTimer(
                withTimeInterval: Constants.cpuRefreshInterval,
                repeats: true
            ) { [weak self] _ in
                self?.refresh()
            }
            RunLoop.main.add(self.refreshTimer!, forMode: .common)
        }

        if Thread.isMainThread { start() }
        else { DispatchQueue.main.async(execute: start) }
    }
}
