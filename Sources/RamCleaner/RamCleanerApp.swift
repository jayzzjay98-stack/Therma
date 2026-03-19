import SwiftUI

@main
struct ThermaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                preferences: AppContext.shared.preferences,
                updateManager: AppContext.shared.updateManager
            )
        }
    }
}
