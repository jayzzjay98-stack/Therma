import Foundation
import Darwin

// MARK: - Memory Stats Provider
// Single Responsibility: reads raw memory statistics from the macOS kernel.

final class MemoryStatsProvider {

    // CR-03: Cache the host port once — calling mach_host_self() + deallocate every 2s
    // causes spurious kern errors. The host port is a well-known cached send right.
    private let hostPort: host_t = mach_host_self()

    private var cachedSwapMB: Double = 0
    private var swapLastReadAt: Date = .distantPast

    // MARK: - Snapshot

    struct Snapshot {
        let totalGB: Double
        let usedGB: Double
        let cachedGB: Double
        let swapUsedMB: Double
        let usagePercent: Int
    }

    // MARK: - Public API

    /// Fetches a fresh memory snapshot. Returns nil on kernel error.
    func fetchSnapshot() -> Result<Snapshot, MemoryError> {
        guard let vmStats = readVMStats() else {
            return .failure(.vmStatsFailed)
        }
        guard let totalBytes = readTotalMemory() else {
            return .failure(.totalMemoryFailed)
        }

        let pageSize = Double(vm_kernel_page_size)
        let snapshot = buildSnapshot(vmStats: vmStats, totalBytes: totalBytes, pageSize: pageSize)
        return .success(snapshot)
    }

    // MARK: - Private Helpers

    private func readVMStats() -> vm_statistics64? {
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &vmStats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(hostPort, HOST_VM_INFO64, intPtr, &count)
            }
        }

        return result == KERN_SUCCESS ? vmStats : nil
    }

    private func readTotalMemory() -> Double? {
        var total: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        guard sysctlbyname("hw.memsize", &total, &size, nil, 0) == 0 else { return nil }
        return Double(total)
    }

    private func readSwapUsage() -> Double {
        let now = Date()
        guard now.timeIntervalSince(swapLastReadAt) >= 10 else { return cachedSwapMB }
        var swapUsage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        guard sysctlbyname("vm.swapusage", &swapUsage, &size, nil, 0) == 0 else { return cachedSwapMB }
        cachedSwapMB = Double(swapUsage.xsu_used) / Constants.bytesPerMB
        swapLastReadAt = now
        return cachedSwapMB
    }

    private func buildSnapshot(
        vmStats: vm_statistics64,
        totalBytes: Double,
        pageSize: Double
    ) -> Snapshot {
        // Activity Monitor formula:
        // App Memory  = (internal_page_count − purgeable_count) × pageSize
        // Wired       = wire_count × pageSize
        // Compressed  = compressor_page_count × pageSize
        // Used        = App + Wired + Compressed
        // CR-01: Guard against UInt32 underflow — purgeable can transiently exceed internal.
        let safeAppPages     = vmStats.internal_page_count > vmStats.purgeable_count
                                ? vmStats.internal_page_count - vmStats.purgeable_count : 0
        let appMemory        = Double(safeAppPages) * pageSize
        let wiredMemory      = Double(vmStats.wire_count) * pageSize
        let compressedMemory = Double(vmStats.compressor_page_count) * pageSize
        let usedBytes        = appMemory + wiredMemory + compressedMemory
        let cachedBytes      = Double(vmStats.external_page_count + vmStats.purgeable_count) * pageSize

        let totalGB   = totalBytes / Constants.bytesPerGB
        let usedGB    = max(0, usedBytes / Constants.bytesPerGB)
        let cachedGB  = cachedBytes / Constants.bytesPerGB
        let percent   = totalBytes > 0 ? min(100, Int((usedBytes / totalBytes) * 100)) : 0

        return Snapshot(
            totalGB: totalGB,
            usedGB: usedGB,
            cachedGB: cachedGB,
            swapUsedMB: readSwapUsage(),
            usagePercent: percent
        )
    }
}

// MARK: - Error Types

enum MemoryError: Error, LocalizedError {
    case vmStatsFailed
    case totalMemoryFailed

    var errorDescription: String? {
        switch self {
        case .vmStatsFailed:    return "Failed to read VM statistics from kernel"
        case .totalMemoryFailed: return "Failed to read total memory size"
        }
    }
}
