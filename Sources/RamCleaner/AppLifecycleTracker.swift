import Foundation
import AppKit

// MARK: - Closed App Signature

struct ClosedAppSignature: Equatable {
    let bundleID: String?
    let localizedName: String
    let bundlePath: String?
    let executablePath: String?
    let terminatedAt: Date

    init(
        bundleID: String?,
        localizedName: String,
        bundlePath: String?,
        executablePath: String?,
        terminatedAt: Date = Date()
    ) {
        self.bundleID = bundleID?.lowercased()
        self.localizedName = localizedName.lowercased()
        self.bundlePath = bundlePath?.lowercased()
        self.executablePath = executablePath?.lowercased()
        self.terminatedAt = terminatedAt
    }

    var tokens: Set<String> {
        var out = Set<String>()

        if !localizedName.isEmpty {
            out.insert(localizedName)
            localizedName
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map { String($0) }
                .filter { $0.count >= Constants.closedAppTokenMinimumLength }
                .forEach { out.insert($0) }
        }

        if let bundleID {
            bundleID
                .split(separator: ".")
                .map { String($0) }
                .filter {
                    $0.count >= Constants.closedAppTokenMinimumLength
                    && $0 != "com"
                    && $0 != "app"
                    && $0 != "helper"
                }
                .forEach { out.insert($0) }
        }

        if let bundlePath {
            let bundleName = URL(fileURLWithPath: bundlePath)
                .deletingPathExtension()
                .lastPathComponent
                .lowercased()
            if !bundleName.isEmpty { out.insert(bundleName) }
        }

        if let executablePath {
            let executableName = URL(fileURLWithPath: executablePath)
                .lastPathComponent
                .lowercased()
            if !executableName.isEmpty { out.insert(executableName) }
        }

        return out
    }

    func matches(commandLine: String, commandName: String, helperIndicators: [String]) -> Bool {
        let line = commandLine.lowercased()
        let name = commandName.lowercased()

        if let executablePath, !executablePath.isEmpty, line.contains(executablePath) {
            return true
        }

        if let bundlePath, !bundlePath.isEmpty, line.contains(bundlePath) {
            return true
        }

        let matchedToken = tokens.contains { token in
            name.contains(token) || line.contains(token)
        }

        guard matchedToken else { return false }

        if name == localizedName || line.contains("/\(localizedName).app/") {
            return true
        }

        return helperIndicators.contains { indicator in
            name.contains(indicator) || line.contains(indicator)
        }
    }
}

// MARK: - App Lifecycle Tracker

final class AppLifecycleTracker {

    private let notificationCenter: NotificationCenter
    private let lock = NSLock()
    private var observers: [NSObjectProtocol] = []
    private var recentlyClosedApps: [ClosedAppSignature] = []

    init(notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter) {
        self.notificationCenter = notificationCenter
        startObserving()
    }

    deinit {
        for observer in observers {
            notificationCenter.removeObserver(observer)
        }
    }

    func snapshot() -> [ClosedAppSignature] {
        lock.lock()
        defer { lock.unlock() }
        pruneLocked(referenceDate: Date())
        return recentlyClosedApps
    }

    private func startObserving() {
        let didTerminate = notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.recordTermination(note)
        }

        let didLaunch = notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.removeRelaunchedApp(note)
        }

        observers = [didTerminate, didLaunch]
    }

    private func recordTermination(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }

        let signature = ClosedAppSignature(
            bundleID: app.bundleIdentifier,
            localizedName: app.localizedName ?? "",
            bundlePath: app.bundleURL?.path,
            executablePath: app.executableURL?.path
        )

        guard !signature.localizedName.isEmpty || signature.bundleID != nil else { return }

        lock.lock()
        defer { lock.unlock() }

        pruneLocked(referenceDate: signature.terminatedAt)
        recentlyClosedApps.removeAll { existing in
            existing.bundleID == signature.bundleID
            && existing.localizedName == signature.localizedName
            && existing.bundlePath == signature.bundlePath
            && existing.executablePath == signature.executablePath
        }
        recentlyClosedApps.insert(signature, at: 0)
        if recentlyClosedApps.count > Constants.maxTrackedClosedApps {
            recentlyClosedApps = Array(recentlyClosedApps.prefix(Constants.maxTrackedClosedApps))
        }
    }

    private func removeRelaunchedApp(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }

        let bundleID = app.bundleIdentifier?.lowercased()
        let localizedName = (app.localizedName ?? "").lowercased()
        let bundlePath = app.bundleURL?.path.lowercased()
        let executablePath = app.executableURL?.path.lowercased()

        lock.lock()
        defer { lock.unlock() }

        recentlyClosedApps.removeAll { signature in
            signature.bundleID == bundleID
            || (!localizedName.isEmpty && signature.localizedName == localizedName)
            || (bundlePath != nil && signature.bundlePath == bundlePath)
            || (executablePath != nil && signature.executablePath == executablePath)
        }
    }

    private func pruneLocked(referenceDate: Date) {
        recentlyClosedApps.removeAll {
            referenceDate.timeIntervalSince($0.terminatedAt) > Constants.closedAppRetentionSeconds
        }
    }
}
