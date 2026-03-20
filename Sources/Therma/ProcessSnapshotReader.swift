import Foundation
import AppKit

// MARK: - ProcessSnapshotReader
// Reads the live process table via /bin/ps. No side effects beyond spawning ps.

struct ProcessSnapshotReader {
    func readTopProcesses(
        limit: Int,
        nameCleaner: (String) -> String
    ) -> [RunningProcess] {
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-arcwwwxo", "pid=,rss=,comm="]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do { try process.run() } catch { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard let output = String(data: data, encoding: .utf8) else { return [] }

        var memoryByName: [String: Double] = [:]
        for line in output.components(separatedBy: "\n") where !line.isEmpty {
            let parts = line.trimmingCharacters(in: .whitespaces)
                .split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
            guard parts.count == 3, let rss = Double(parts[1]) else { continue }

            let memoryMB = rss / Constants.kbPerMB
            guard memoryMB >= Constants.minimumDisplayMemoryMB else { continue }

            let name = nameCleaner(String(parts[2]))
            guard !name.isEmpty else { continue }
            memoryByName[name, default: 0] += memoryMB
        }

        return memoryByName
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { RunningProcess(pid: -1, name: $0.key, memoryMB: $0.value) }
    }

    func readAllEntries() -> [ProcessEntry] {
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "pid=,ppid=,rss=,ucomm=,args="]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do { try process.run() } catch { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard let output = String(data: data, encoding: .utf8) else { return [] }

        return output.components(separatedBy: "\n").compactMap { line in
            let parts = line.trimmingCharacters(in: .whitespaces)
                .split(separator: " ", maxSplits: 4, omittingEmptySubsequences: true)
            guard parts.count >= 5,
                  let pid = Int32(parts[0]),
                  let ppid = Int32(parts[1]),
                  let rss = Double(parts[2])
            else { return nil }

            return ProcessEntry(
                pid: pid,
                ppid: ppid,
                rssKB: rss,
                commandName: String(parts[3]).lowercased(),
                commandLine: String(parts[4]).lowercased()
            )
        }
    }
}

// MARK: - ActiveAppSignatureBuilder
// Builds an ActiveAppSignatures snapshot from NSWorkspace — main-thread safe.

struct ActiveAppSignatureBuilder {
    func build() -> ActiveAppSignatures {
        var pids = Set<Int32>()
        var names = Set<String>()
        var bundleIDs = Set<String>()
        var execPaths = Set<String>()

        for app in NSWorkspace.shared.runningApplications {
            pids.insert(app.processIdentifier)

            if let bundleID = app.bundleIdentifier?.lowercased() {
                bundleIDs.insert(bundleID)
                for part in bundleID.split(separator: ".")
                where part.count > 2 && part != "com" && part != "app" && part != "helper" {
                    names.insert(String(part))
                }
            }

            if let localizedName = app.localizedName?.lowercased() {
                names.insert(localizedName)
            }

            if let executablePath = app.executableURL?.path.lowercased() {
                execPaths.insert(executablePath)
                if let range = executablePath.range(of: ".app/") ?? executablePath.range(of: ".app") {
                    let appName = URL(fileURLWithPath: String(executablePath[..<range.lowerBound])).lastPathComponent
                    names.insert(appName)
                }
            }
        }

        return ActiveAppSignatures(
            pids: pids,
            names: names,
            bundleIDs: bundleIDs,
            execPaths: execPaths
        )
    }
}
