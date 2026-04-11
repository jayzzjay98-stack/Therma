import Foundation
import IOKit

@Observable
final class GPUMonitor {
    var usagePercent: Double?
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

    func refresh() {
        usagePercent = Self.fetchGPUUtilization()
        lastUpdated = Date()
    }

    private static func fetchGPUUtilization() -> Double? {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator) == KERN_SUCCESS else {
            return nil
        }

        var utilization: Double? = nil

        while let svc = IOIteratorNext(iterator) as io_object_t?, svc != 0 {
            defer { IOObjectRelease(svc) }
            guard let unmanaged = IORegistryEntryCreateCFProperty(svc, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0) else {
                continue
            }

            if let dict = unmanaged.takeRetainedValue() as? [String: Any], let util = dict["Device Utilization %"] as? Int {
                // If there are multiple GPUs (e.g. Intel + AMD, or Mac Studio Ultra), we could take max or average.
                // For Apple Silicon, there's typically one AppleAGX accelerator.
                utilization = max(utilization ?? 0, Double(util))
            }
        }

        return utilization
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
