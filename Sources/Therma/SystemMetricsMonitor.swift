import Foundation
import Darwin

struct NetworkThroughput {
    let downloadBytesPerSecond: Double?
    let uploadBytesPerSecond: Double?
}

enum ThroughputFormatter {
    static func string(for bytesPerSecond: Double?) -> String {
        guard let bytesPerSecond, bytesPerSecond.isFinite, bytesPerSecond >= 0 else { return "--" }
        switch bytesPerSecond {
        case ..<1_024:
            return String(format: "%.0f B/s", bytesPerSecond)
        case ..<1_048_576:
            return String(format: "%.1f KB/s", bytesPerSecond / 1_024)
        default:
            return String(format: "%.2f MB/s", bytesPerSecond / 1_048_576)
        }
    }

    static func compactString(for bytesPerSecond: Double?) -> String {
        guard let bytesPerSecond, bytesPerSecond.isFinite, bytesPerSecond >= 0 else { return "--" }
        switch bytesPerSecond {
        case ..<1_024:
            return String(format: "%.0fB", bytesPerSecond)
        case ..<1_048_576:
            return String(format: "%.1fK", bytesPerSecond / 1_024)
        default:
            return String(format: "%.2fM", bytesPerSecond / 1_048_576)
        }
    }
}

@Observable
final class SystemMetricsMonitor {
    var cpuUsagePercent: Double?
    var downloadBytesPerSecond: Double?
    var uploadBytesPerSecond: Double?
    var lastUpdated: Date = .distantPast

    private let cpuUsageProvider = CPUUsageProvider()
    private let networkProvider = NetworkThroughputProvider()
    private var refreshTimer: Timer?

    init() {
        refresh()
        startTimer()
    }

    deinit {
        refreshTimer?.invalidate()
    }

    var cpuUsageDisplayValue: String {
        guard let cpuUsagePercent else { return "--" }
        return "\(Int(cpuUsagePercent.rounded()))%"
    }

    var downloadSpeedDisplayValue: String {
        ThroughputFormatter.string(for: downloadBytesPerSecond)
    }

    var uploadSpeedDisplayValue: String {
        ThroughputFormatter.string(for: uploadBytesPerSecond)
    }

    var networkMenuBarDisplayValue: String {
        let download = ThroughputFormatter.compactString(for: downloadBytesPerSecond)
        let upload = ThroughputFormatter.compactString(for: uploadBytesPerSecond)

        if download == "--", upload == "--" {
            return "--"
        }

        return "↓\(download) ↑\(upload)"
    }

    func refresh() {
        cpuUsagePercent = cpuUsageProvider.sampleUsagePercent()
        let throughput = networkProvider.sampleThroughput()
        downloadBytesPerSecond = throughput.downloadBytesPerSecond
        uploadBytesPerSecond = throughput.uploadBytesPerSecond
        lastUpdated = Date()
    }

    private func startTimer() {
        let start: () -> Void = { [weak self] in
            guard let self else { return }
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

private struct CPULoadSnapshot {
    let user: UInt64
    let system: UInt64
    let idle: UInt64
    let nice: UInt64
}

private final class CPUUsageProvider {
    private var previousSnapshot: CPULoadSnapshot?

    func sampleUsagePercent() -> Double? {
        guard let current = readSnapshot() else { return nil }
        defer { previousSnapshot = current }

        guard let previousSnapshot else { return nil }

        let user = current.user - previousSnapshot.user
        let system = current.system - previousSnapshot.system
        let idle = current.idle - previousSnapshot.idle
        let nice = current.nice - previousSnapshot.nice
        let active = Double(user + system + nice)
        let total = active + Double(idle)
        guard total > 0 else { return nil }
        return active / total * 100
    }

    private func readSnapshot() -> CPULoadSnapshot? {
        var info = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { pointer in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, pointer, &count)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        return CPULoadSnapshot(
            user: UInt64(info.cpu_ticks.0),
            system: UInt64(info.cpu_ticks.1),
            idle: UInt64(info.cpu_ticks.2),
            nice: UInt64(info.cpu_ticks.3)
        )
    }
}

private struct NetworkCounterSnapshot {
    let receivedBytes: UInt64
    let sentBytes: UInt64
    let timestamp: Date
}

private final class NetworkThroughputProvider {
    private var previousSnapshot: NetworkCounterSnapshot?

    func sampleThroughput() -> NetworkThroughput {
        guard let current = readSnapshot() else {
            return NetworkThroughput(downloadBytesPerSecond: nil, uploadBytesPerSecond: nil)
        }
        defer { previousSnapshot = current }

        guard let previousSnapshot else {
            return NetworkThroughput(downloadBytesPerSecond: 0, uploadBytesPerSecond: 0)
        }

        let elapsed = current.timestamp.timeIntervalSince(previousSnapshot.timestamp)
        guard elapsed > 0 else {
            return NetworkThroughput(downloadBytesPerSecond: nil, uploadBytesPerSecond: nil)
        }

        let download = Double(current.receivedBytes &- previousSnapshot.receivedBytes) / elapsed
        let upload = Double(current.sentBytes &- previousSnapshot.sentBytes) / elapsed
        return NetworkThroughput(
            downloadBytesPerSecond: max(0, download),
            uploadBytesPerSecond: max(0, upload)
        )
    }

    private func readSnapshot() -> NetworkCounterSnapshot? {
        var interfacePointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfacePointer) == 0, let first = interfacePointer else { return nil }
        defer { freeifaddrs(interfacePointer) }

        var receivedBytes: UInt64 = 0
        var sentBytes: UInt64 = 0
        var cursor: UnsafeMutablePointer<ifaddrs>? = first

        while let current = cursor {
            let interface = current.pointee
            let flags = Int32(interface.ifa_flags)
            let family = interface.ifa_addr?.pointee.sa_family

            if family == UInt8(AF_LINK),
               flags & IFF_UP != 0,
               flags & IFF_LOOPBACK == 0,
               let dataPointer = interface.ifa_data?.assumingMemoryBound(to: if_data.self) {
                let data = dataPointer.pointee
                receivedBytes += UInt64(data.ifi_ibytes)
                sentBytes += UInt64(data.ifi_obytes)
            }

            cursor = interface.ifa_next
        }

        return NetworkCounterSnapshot(
            receivedBytes: receivedBytes,
            sentBytes: sentBytes,
            timestamp: Date()
        )
    }
}
