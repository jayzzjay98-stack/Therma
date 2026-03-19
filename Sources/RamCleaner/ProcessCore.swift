import Foundation

// MARK: - ProcessEntry

struct ProcessEntry {
    let pid: Int32
    let ppid: Int32
    let rssKB: Double
    let commandName: String
    let commandLine: String
}

// MARK: - ActiveAppSignatures

struct ActiveAppSignatures {
    let pids: Set<Int32>
    let names: Set<String>
    let bundleIDs: Set<String>
    let execPaths: Set<String>

    func matchesAppName(_ name: String) -> Bool {
        names.contains(name)
            || bundleIDs.contains { $0.contains(name) }
            || execPaths.contains { $0.contains(name) }
    }

    func matchesPath(_ commandLine: String) -> Bool {
        names.contains(where: { commandLine.contains($0) })
            || bundleIDs.contains(where: { commandLine.contains($0) })
    }

    func contains(signature: ClosedAppSignature) -> Bool {
        if let bundleID = signature.bundleID, bundleIDs.contains(bundleID) {
            return true
        }

        if !signature.localizedName.isEmpty, names.contains(signature.localizedName) {
            return true
        }

        if let executablePath = signature.executablePath, execPaths.contains(executablePath) {
            return true
        }

        return signature.tokens.contains { names.contains($0) || bundleIDs.contains($0) }
    }
}
