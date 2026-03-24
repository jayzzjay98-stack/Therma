import Foundation
import AppKit

// MARK: - Data Models

struct RunningProcess: Identifiable {
    let id = UUID()
    let pid: Int32
    let name: String
    let memoryMB: Double
}

enum MemoryPressure: String {
    case low    = "Low"
    case medium = "Medium"
    case high   = "High"
}

private struct CleanBaseline: Sendable {
    let usedGB: Double
    let cachedGB: Double
}

private struct DeepCleanBaseline: Sendable {
    let cleanBaseline: CleanBaseline
    let recentlyClosedApps: [ClosedAppSignature]
}

private struct DeepCleanPreparation: Sendable {
    let steps: [String]
}

typealias CleanCompletion = @Sendable (Bool, String) -> Void
typealias PurgeOperationResult = Result<Void, PurgeError>

// MARK: - RAM Monitor (Coordinator)
// Responsibility: own the published state, coordinate sub-managers, drive timers.

@Observable
final class RAMMonitor: @unchecked Sendable {

    // MARK: - Published State

    var usedGB: Double           = 0
    var totalGB: Double          = 0
    var usagePercent: Int        = 0
    var pressure: MemoryPressure = .low
    var topProcesses: [RunningProcess] = []
    var swapUsedMB: Double       = 0
    var cachedGB: Double         = 0
    var chipName: String         = "Apple Silicon"
    var lastError: String?
    /// Stays true until the first process list arrives — drives the "Scanning..." placeholder.
    var isLoadingProcesses: Bool = true

    // MARK: - Sub-managers

    private let statsProvider  = MemoryStatsProvider()
    private let processManager = ProcessManager()
    private let cacheManager   = CacheManager()
    private let purgeManager   = PurgeManager()
    private let appLifecycleTracker = AppLifecycleTracker()
    private let autoRefreshStats: Bool
    private var processSubscribers = Set<String>()

    // MARK: - Timers

    private var backgroundTimer: Timer?
    private var foregroundTimer: Timer?

    // MARK: - Init / Deinit

    init(autoRefreshStats: Bool = true) {
        self.autoRefreshStats = autoRefreshStats
        chipName = ChipDetector.detect()
        refreshStats()
        if autoRefreshStats {
            startBackgroundTimer()
        }
    }

    deinit {
        backgroundTimer?.invalidate()
        foregroundTimer?.invalidate()
    }

    // MARK: - Public Refresh

    func refresh() {
        refreshStats()
        refreshProcesses()
    }

    func refreshStatsOnly() {
        refreshStats()
    }

    // MARK: - Timer Control

    func setProcessMonitoring(_ enabled: Bool, source: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            if enabled {
                let inserted = self.processSubscribers.insert(source).inserted
                if inserted, self.processSubscribers.count == 1 {
                    self.startForegroundTimer()
                } else if inserted {
                    self.refreshProcesses()
                }
            } else {
                self.processSubscribers.remove(source)
                if self.processSubscribers.isEmpty {
                    self.stopForegroundTimer()
                }
            }
        }
    }

    private func startForegroundTimer() {
        foregroundTimer?.invalidate()
        refreshProcesses()
        foregroundTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.foregroundRefreshInterval,
            repeats: true
        ) { [weak self] _ in self?.refreshProcesses() }
        RunLoop.main.add(foregroundTimer!, forMode: .common)
    }

    private func stopForegroundTimer() {
        foregroundTimer?.invalidate()
        foregroundTimer = nil
    }

    // MARK: - Clean Operations

    /// Quick Clean: just `purge` the disk-cache layer.
    func cleanMemory(completion: @escaping CleanCompletion) {
        let baseline = captureCleanBaseline()

        purgeManager.purge { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success:
                    self.finishClean(
                        baseline: baseline,
                        prefix: "",
                        completion: completion
                    )
                case .failure(let error):
                    completion(false, error.localizedDescription)
                }
            }
        }
    }

    /// Deep Clean: orphan kill + cache clear (parallel) → purge → report.
    /// Orphan scan and cache clear run concurrently — roughly 30% faster than serial,
    /// and avoids the steps-array mutation race that existed in the original flow.
    func deepCleanMemory(completion: @escaping CleanCompletion) {
        let baseline = captureDeepCleanBaseline()

        Self.prepareDeepClean(
            processManager: processManager,
            cacheManager: cacheManager,
            purgeManager: purgeManager,
            recentlyClosedApps: baseline.recentlyClosedApps
        ) { [weak self] preparation in
            guard let self else { return }

            self.purgeManager.purge { [weak self] result in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.finishDeepClean(
                        result: result,
                        baseline: baseline,
                        preparation: preparation,
                        completion: completion
                    )
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func startBackgroundTimer() {
        let start: () -> Void = { [weak self] in
            guard let self else { return }
            self.backgroundTimer?.invalidate()
            self.backgroundTimer = Timer.scheduledTimer(
                withTimeInterval: Constants.backgroundRefreshInterval,
                repeats: true
            ) { [weak self] _ in self?.refreshStats() }
            RunLoop.main.add(self.backgroundTimer!, forMode: .common)
        }

        if Thread.isMainThread { start() }
        else { DispatchQueue.main.async(execute: start) }
    }

    private func refreshStats() {
        switch statsProvider.fetchSnapshot() {
        case .success(let snapshot):
            totalGB      = snapshot.totalGB
            usedGB       = snapshot.usedGB
            cachedGB     = snapshot.cachedGB
            swapUsedMB   = snapshot.swapUsedMB
            usagePercent = snapshot.usagePercent
            pressure     = computePressure(usagePercent: snapshot.usagePercent)
            lastError    = nil
        case .failure(let error):
            lastError = error.localizedDescription
        }
    }

    private func refreshProcesses() {
        processManager.fetchTopProcesses { [weak self] processes in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.topProcesses = processes
                self.isLoadingProcesses = false   // clears the spinner after first fetch
            }
        }
    }

    private func computePressure(usagePercent: Int) -> MemoryPressure {
        switch usagePercent {
        case ..<Constants.pressureMediumThreshold: return .low
        case ..<Constants.pressureHighThreshold:   return .medium
        default:                                    return .high
        }
    }

    private func captureCleanBaseline() -> CleanBaseline {
        CleanBaseline(usedGB: usedGB, cachedGB: cachedGB)
    }

    private func captureDeepCleanBaseline() -> DeepCleanBaseline {
        DeepCleanBaseline(
            cleanBaseline: captureCleanBaseline(),
            recentlyClosedApps: appLifecycleTracker.snapshot()
        )
    }

    private func finishDeepClean(
        result: PurgeOperationResult,
        baseline: DeepCleanBaseline,
        preparation: DeepCleanPreparation,
        completion: @escaping CleanCompletion
    ) {
        switch result {
        case .failure(let error):
            completion(false, error.localizedDescription)
        case .success:
            finishClean(
                baseline: baseline.cleanBaseline,
                prefix: "Deep clean done! ",
                steps: preparation.steps + ["System memory cache purged"],
                completion: completion
            )
        }
    }

    private func finishClean(
        baseline: CleanBaseline,
        prefix: String,
        steps: [String] = [],
        completion: @escaping CleanCompletion
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.postCleanStatsDelay) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.refreshStats()
                let freed = max(
                    0,
                    (baseline.usedGB - self.usedGB) + (baseline.cachedGB - self.cachedGB)
                )
                let summary = String(format: "✅ \(prefix)Freed %.1f GB", freed)
                completion(true, ([summary] + steps).joined(separator: "\n"))
                self.refreshProcesses()
            }
        }
    }

    private static func prepareDeepClean(
        processManager: ProcessManager,
        cacheManager: CacheManager,
        purgeManager: PurgeManager,
        recentlyClosedApps: [ClosedAppSignature],
        completion: @escaping @Sendable (DeepCleanPreparation) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let group = DispatchGroup()
            var orphanSteps: [String] = []
            var cacheSteps: [String] = []

            group.enter()
            processManager.findLeftoverProcesses(recentlyClosedApps: recentlyClosedApps) { found in
                var killed = 0
                var killedMB: Double = 0
                for process in found where processManager.terminate(pid: process.pid, aggressive: true) {
                    killed += 1
                    killedMB += process.memoryMB
                }
                orphanSteps = killed > 0
                    ? ["Killed \(killed) leftover processes from closed apps (\(Int(killedMB)) MB)"]
                    : ["No leftover processes from closed apps found"]
                group.leave()
            }

            group.enter()
            DispatchQueue.main.async {
                cacheSteps = cacheManager.clearCaches()
                group.leave()
            }

            purgeManager.sendMemoryPressureWarning()
            group.wait()

            completion(
                DeepCleanPreparation(
                    steps: orphanSteps + cacheSteps + ["Memory pressure warning sent"]
                )
            )
        }
    }
}
