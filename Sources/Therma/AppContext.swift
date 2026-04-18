import Foundation

@MainActor
final class AppContext {
    static let shared = AppContext()

    let ramMonitor    = RAMMonitor(autoRefreshStats: false)
    let cpuMonitor    = CPUMonitor(autoRefresh: false)
    let gpuMonitor    = GPUMonitor(autoRefresh: false)
    let systemMetricsMonitor = SystemMetricsMonitor(autoRefresh: false)
    let preferences   = MenuBarPreferences()
    let updateManager = UpdateManager()
    let alertManager  = AlertManager()

    private var refreshCoordinator: Timer?
    private var refreshTickCount = 0

    private init() {
        alertManager.requestPermissionIfNeeded()
        startRefreshCoordinator()
    }

    private func startRefreshCoordinator() {
        refreshCoordinator = Timer.scheduledTimer(
            withTimeInterval: Constants.systemMetricsRefreshInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleRefreshTick()
            }
        }
        RunLoop.main.add(refreshCoordinator!, forMode: .common)
    }

    private func handleRefreshTick() {
        refreshTickCount += 1

        systemMetricsMonitor.refresh()

        if refreshTickCount % Int(Constants.backgroundRefreshInterval / Constants.systemMetricsRefreshInterval) == 0 {
            ramMonitor.refreshStatsOnly()
            alertManager.check(
                ramPercent: ramMonitor.usagePercent,
                cpuCelsius: cpuMonitor.currentCelsius,
                preferences: preferences
            )
        }

        if refreshTickCount % Int(Constants.cpuRefreshInterval / Constants.systemMetricsRefreshInterval) == 0 {
            cpuMonitor.refresh()
        }

        if refreshTickCount % Int(Constants.gpuRefreshInterval / Constants.systemMetricsRefreshInterval) == 0 {
            gpuMonitor.refresh()
        }

        NotificationCenter.default.post(name: .thermaStatusBarDidChange, object: nil)
    }
}
