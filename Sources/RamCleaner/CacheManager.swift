import Foundation
import AppKit
import OSLog

// MARK: - Cache Manager

// no mutable state — FileManager and Logger are both thread-safe per Apple docs
final class CacheManager: @unchecked Sendable {

    private let fileManager = FileManager.default
    private let auditLog    = Logger(subsystem: "com.justkay.therma", category: "audit")

    // MARK: - Public API

    /// Clears known developer and app caches. Returns a list of human-readable results.
    func clearCaches() -> [String] {
        var results: [String] = []
        let home = fileManager.homeDirectoryForCurrentUser.path

        results += clearXcodeDerivedData(home: home)
        results += clearAppCaches(home: home)
        results += clearGradleCaches(home: home)

        return results
    }

    // MARK: - Xcode

    private func clearXcodeDerivedData(home: String) -> [String] {
        let xcodeIsRunning = NSWorkspace.shared.runningApplications
            .contains { $0.bundleIdentifier == "com.apple.dt.Xcode" }

        guard !xcodeIsRunning else {
            return ["Xcode is running — skipped DerivedData"]
        }

        let path = "\(home)/Library/Developer/Xcode/DerivedData"
        let cleared = clearDirectory(at: path)
        return cleared ? ["Xcode DerivedData cleared"] : []
    }

    // MARK: - App Caches

    private func clearAppCaches(home: String) -> [String] {
        let cachesRoot = "\(home)/Library/Caches"
        let targets = [
            "\(cachesRoot)/com.apple.dt.Xcode",
            "\(cachesRoot)/org.carthage.CarthageKit",
            "\(cachesRoot)/com.googlecode.iterm2",
            "\(cachesRoot)/Google",
            "\(cachesRoot)/JetBrains",
        ]

        return targets.compactMap { path in
            guard clearDirectory(at: path) else { return nil }
            return "Cache cleared: \(URL(fileURLWithPath: path).lastPathComponent)"
        }
    }

    // MARK: - Gradle

    private func clearGradleCaches(home: String) -> [String] {
        let path = "\(home)/.gradle/caches"
        return clearDirectory(at: path) ? ["Gradle caches cleared"] : []
    }

    // MARK: - Helpers

    /// Removes all items inside `path` (but keeps the directory itself).
    /// - Returns: true if at least one item was removed.
    private func clearDirectory(at path: String) -> Bool {
        guard fileManager.fileExists(atPath: path) else { return false }

        do {
            let items = try fileManager.contentsOfDirectory(atPath: path)
            guard !items.isEmpty else { return false }
            let dirURL = URL(fileURLWithPath: path)
            for item in items {
                // use appendingPathComponent rather than string concat to avoid path traversal
                let itemURL = dirURL.appendingPathComponent(item)
                auditLog.info("cache remove: \(itemURL.path, privacy: .public)")
                try fileManager.removeItem(at: itemURL)
            }
            return true
        } catch {
            return false
        }
    }
}
