import Foundation
import IOKit

struct GPUStats {
    let deviceUtilPercent: Double
    let rendererUtilPercent: Double
    let tilerUtilPercent: Double
    let inUseMemoryBytes: Int64
    let allocatedMemoryBytes: Int64

    var inUseMemoryGB: Double { Double(inUseMemoryBytes) / 1_073_741_824 }
    var allocatedMemoryGB: Double { Double(allocatedMemoryBytes) / 1_073_741_824 }
    var inUseMemoryMB: Double { Double(inUseMemoryBytes) / 1_048_576 }
}

@Observable
final class GPUMonitor {
    var usagePercent: Double?
    var stats: GPUStats?
    var lastUpdated: Date = .distantPast

    private let autoRefresh: Bool
    private var refreshTimer: Timer?

    init(autoRefresh: Bool = true) {
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
        guard let usagePercent else { return "--" }
        return "\(Int(usagePercent.rounded()))%"
    }

    var rendererDisplayValue: String {
        guard let s = stats else { return "--" }
        return "\(Int(s.rendererUtilPercent.rounded()))%"
    }

    var tilerDisplayValue: String {
        guard let s = stats else { return "--" }
        return "\(Int(s.tilerUtilPercent.rounded()))%"
    }

    var vramDisplayValue: String {
        guard let s = stats else { return "--" }
        let mb = s.inUseMemoryMB
        if mb >= 1024 { return String(format: "%.1f GB", s.inUseMemoryGB) }
        return String(format: "%.0f MB", mb)
    }

    func refresh() {
        let fetched = Self.fetchGPUStats()
        stats = fetched
        usagePercent = fetched?.deviceUtilPercent
        lastUpdated = Date()
    }

    private static func fetchGPUStats() -> GPUStats? {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator) == KERN_SUCCESS else {
            return nil
        }

        var best: GPUStats? = nil

        while case let svc = IOIteratorNext(iterator), svc != 0 {
            defer { IOObjectRelease(svc) }
            guard let unmanaged = IORegistryEntryCreateCFProperty(svc, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0) else { continue }
            guard let dict = unmanaged.takeRetainedValue() as? [String: Any] else { continue }

            let device   = (dict["Device Utilization %"]   as? Int).map(Double.init) ?? 0
            let renderer = (dict["Renderer Utilization %"] as? Int).map(Double.init) ?? 0
            let tiler    = (dict["Tiler Utilization %"]    as? Int).map(Double.init) ?? 0
            let inUse    = dict["In use system memory"]    as? Int64 ?? 0
            let alloc    = dict["Alloc system memory"]     as? Int64
                        ?? (dict["Allocated PB Size"]      as? Int64 ?? 0)

            let candidate = GPUStats(
                deviceUtilPercent: device,
                rendererUtilPercent: renderer,
                tilerUtilPercent: tiler,
                inUseMemoryBytes: inUse,
                allocatedMemoryBytes: alloc
            )

            if best == nil || device > best!.deviceUtilPercent {
                best = candidate
            }
        }

        return best
    }

    private func startTimer() {
        let start: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.refreshTimer?.invalidate()
            self.refreshTimer = Timer.scheduledTimer(
                withTimeInterval: Constants.systemMetricsRefreshInterval,
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
