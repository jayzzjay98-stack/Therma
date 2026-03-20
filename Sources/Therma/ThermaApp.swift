import SwiftUI

@main
struct ThermaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                preferences: AppContext.shared.preferences,
                ramMonitor: AppContext.shared.ramMonitor,
                cpuMonitor: AppContext.shared.cpuMonitor,
                systemMetricsMonitor: AppContext.shared.systemMetricsMonitor,
                updateManager: AppContext.shared.updateManager
            )
        }
    }
}
