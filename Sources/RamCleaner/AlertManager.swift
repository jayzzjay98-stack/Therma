import Foundation
import UserNotifications

// MARK: - Alert Manager
// Posts local macOS notifications when RAM or CPU thresholds are crossed.
// Cooldown prevents repeated alerts — one notification per alert type per 5 minutes.

@MainActor
final class AlertManager {

    private var lastRAMAlertDate: Date?
    private var lastCPUAlertDate: Date?
    private let cooldown: TimeInterval = 300 // 5 minutes

    // Called after every stats refresh. Checks thresholds and posts if needed.
    func check(ramPercent: Int, cpuCelsius: Double?, preferences: MenuBarPreferences) {
        if preferences.ramAlertEnabled, Double(ramPercent) >= preferences.ramAlertThreshold {
            postIfCooledDown(alertKey: "ram") { [self] in
                guard isExpired(lastRAMAlertDate) else { return }
                lastRAMAlertDate = Date()
                post(
                    title: "High Memory Usage",
                    body: "RAM usage is at \(ramPercent)% — consider clearing memory.",
                    identifier: "therma.alert.ram"
                )
            }
        }

        if preferences.cpuAlertEnabled,
           let cpu = cpuCelsius,
           cpu >= preferences.cpuAlertThreshold {
            postIfCooledDown(alertKey: "cpu") { [self] in
                guard isExpired(lastCPUAlertDate) else { return }
                lastCPUAlertDate = Date()
                let formatted = preferences.formatCelsius(cpu)
                post(
                    title: "CPU Running Hot",
                    body: "Temperature is \(formatted) — give your Mac a moment to cool down.",
                    identifier: "therma.alert.cpu"
                )
            }
        }
    }

    // Requests notification permission on first use. Safe to call multiple times.
    func requestPermissionIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: - Private

    private func isExpired(_ date: Date?) -> Bool {
        guard let date else { return true }
        return Date().timeIntervalSince(date) >= cooldown
    }

    private func postIfCooledDown(alertKey: String, block: () -> Void) {
        block()
    }

    private func post(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
