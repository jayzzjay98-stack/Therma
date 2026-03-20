import Foundation

@MainActor
final class AppContext {
    static let shared = AppContext()

    let ramMonitor    = RAMMonitor()
    let cpuMonitor    = CPUMonitor()
    let systemMetricsMonitor = SystemMetricsMonitor()
    let preferences   = MenuBarPreferences()
    let updateManager = UpdateManager()
    let alertManager  = AlertManager()

    private var alertTimer: Timer?

    private init() {
        alertManager.requestPermissionIfNeeded()
        startAlertTimer()
    }

    private func startAlertTimer() {
        alertTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.backgroundRefreshInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.alertManager.check(
                    ramPercent: self.ramMonitor.usagePercent,
                    cpuCelsius: self.cpuMonitor.currentCelsius,
                    preferences: self.preferences
                )
            }
        }
        RunLoop.main.add(alertTimer!, forMode: .common)
    }
}
