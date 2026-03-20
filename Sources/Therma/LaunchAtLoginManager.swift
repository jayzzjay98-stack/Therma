import Foundation
import ServiceManagement

@MainActor
@Observable
final class LaunchAtLoginManager {

    var isEnabled = false
    var message: String?
    var requiresApproval = false

    init() {
        refresh()
    }

    func refresh() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled || status == .requiresApproval
        requiresApproval = status == .requiresApproval

        switch status {
        case .enabled:
            message = "App will launch automatically when you sign in."
        case .requiresApproval:
            message = "Turn it on in System Settings > General > Login Items."
        case .notRegistered:
            message = "App opens only when you launch it yourself."
        case .notFound:
            message = "Launch at login is unavailable in this build."
        @unknown default:
            message = "Launch at login status is unavailable."
        }
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refresh()
        } catch {
            refresh()
            message = error.localizedDescription
        }
    }
}
