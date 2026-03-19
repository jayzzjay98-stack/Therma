import Foundation
import OSLog

// MARK: - LeftoverProcessDetector
// Identifies orphaned processes from apps that have been closed.

struct LeftoverProcessDetector {
    let snapshotReader: ProcessSnapshotReader
    let protectionPolicy: ProcessProtectionPolicy

    init(
        snapshotReader: ProcessSnapshotReader = ProcessSnapshotReader(),
        protectionPolicy: ProcessProtectionPolicy = ProcessProtectionPolicy()
    ) {
        self.snapshotReader = snapshotReader
        self.protectionPolicy = protectionPolicy
    }

    func detectLeftovers(
        active: ActiveAppSignatures,
        recentlyClosedApps: [ClosedAppSignature]
    ) -> [RunningProcess] {
        let entries = snapshotReader.readAllEntries()
        let allPIDs = Set(entries.map(\.pid))
        let childrenByParent = Dictionary(grouping: entries, by: \.ppid)
        let currentPID = getpid()

        let directMatches = directLeftoverMatches(
            entries: entries,
            active: active,
            recentlyClosedApps: recentlyClosedApps,
            allPIDs: allPIDs,
            currentPID: currentPID
        )
        let descendantMatches = collectDescendantPIDs(
            seedPIDs: directMatches,
            childrenByParent: childrenByParent
        )
        let extraAndroidMatches = extraAndroidStudioMatches(
            entries: entries,
            directMatches: directMatches,
            active: active,
            currentPID: currentPID
        )
        let allMatches = directMatches
            .union(descendantMatches)
            .union(extraAndroidMatches)

        return entries.compactMap {
            runningProcessIfMatched(
                $0,
                allMatches: allMatches,
                active: active,
                currentPID: currentPID
            )
        }
    }

    private func directLeftoverMatches(
        entries: [ProcessEntry],
        active: ActiveAppSignatures,
        recentlyClosedApps: [ClosedAppSignature],
        allPIDs: Set<Int32>,
        currentPID: Int32
    ) -> Set<Int32> {
        Set(entries.compactMap { entry in
            guard shouldInspect(entry, active: active, currentPID: currentPID) else { return nil }
            return isOrphanCandidate(
                entry,
                active: active,
                recentlyClosedApps: recentlyClosedApps,
                allPIDs: allPIDs
            ) ? entry.pid : nil
        })
    }

    private func shouldInspect(
        _ entry: ProcessEntry,
        active: ActiveAppSignatures,
        currentPID: Int32
    ) -> Bool {
        guard entry.pid != currentPID,
              !active.pids.contains(entry.pid),
              entry.rssKB / Constants.kbPerMB > Constants.minimumOrphanMemoryMB
        else { return false }

        return !protectionPolicy.isSystemProcess(
            commandLine: entry.commandLine,
            baseName: entry.commandName
        )
    }

    private func isOrphanCandidate(
        _ entry: ProcessEntry,
        active: ActiveAppSignatures,
        recentlyClosedApps: [ClosedAppSignature],
        allPIDs: Set<Int32>
    ) -> Bool {
        matchesRecentlyClosedApp(
            entry,
            active: active,
            recentlyClosedApps: recentlyClosedApps
        )
        || protectionPolicy.isOrphanByAppBundle(commandLine: entry.commandLine, active: active)
        || isOrphanByDeadParent(ppid: entry.ppid, allPIDs: allPIDs)
        || protectionPolicy.isOrphanHelper(entry: entry, active: active)
        || protectionPolicy.isZombieAndroidStudioProcess(entry: entry, active: active)
    }

    private func matchesRecentlyClosedApp(
        _ entry: ProcessEntry,
        active: ActiveAppSignatures,
        recentlyClosedApps: [ClosedAppSignature]
    ) -> Bool {
        recentlyClosedApps.contains { signature in
            !active.contains(signature: signature)
                && signature.matches(
                    commandLine: entry.commandLine,
                    commandName: entry.commandName,
                    helperIndicators: protectionPolicy.helperIndicators
                )
        }
    }

    private func isOrphanByDeadParent(ppid: Int32, allPIDs: Set<Int32>) -> Bool {
        ppid != 1 && !allPIDs.contains(ppid)
    }

    private func extraAndroidStudioMatches(
        entries: [ProcessEntry],
        directMatches: Set<Int32>,
        active: ActiveAppSignatures,
        currentPID: Int32
    ) -> Set<Int32> {
        guard containsAndroidStudioTool(entries: entries, pids: directMatches) else { return [] }

        return Set(entries.compactMap { entry in
            guard entry.pid != currentPID,
                  !active.pids.contains(entry.pid),
                  !protectionPolicy.isSystemProcess(
                    commandLine: entry.commandLine,
                    baseName: entry.commandName
                  ),
                  protectionPolicy.isAndroidStudioTool(entry)
            else { return nil }
            return entry.pid
        })
    }

    private func containsAndroidStudioTool(entries: [ProcessEntry], pids: Set<Int32>) -> Bool {
        pids.contains { pid in
            guard let entry = entries.first(where: { $0.pid == pid }) else { return false }
            return protectionPolicy.isAndroidStudioTool(entry)
        }
    }

    private func collectDescendantPIDs(
        seedPIDs: Set<Int32>,
        childrenByParent: [Int32: [ProcessEntry]]
    ) -> Set<Int32> {
        var visited = Set<Int32>()
        var queue = Array(seedPIDs)

        while let pid = queue.first {
            queue.removeFirst()
            guard visited.insert(pid).inserted else { continue }
            for child in childrenByParent[pid] ?? [] {
                queue.append(child.pid)
            }
        }

        return visited.subtracting(seedPIDs)
    }

    private func runningProcessIfMatched(
        _ entry: ProcessEntry,
        allMatches: Set<Int32>,
        active: ActiveAppSignatures,
        currentPID: Int32
    ) -> RunningProcess? {
        guard allMatches.contains(entry.pid),
              entry.pid != currentPID,
              !active.pids.contains(entry.pid),
              !protectionPolicy.isSystemProcess(
                commandLine: entry.commandLine,
                baseName: entry.commandName
              )
        else { return nil }

        return RunningProcess(
            pid: entry.pid,
            name: protectionPolicy.cleanedDisplayName(from: entry.commandName),
            memoryMB: entry.rssKB / Constants.kbPerMB
        )
    }
}

// MARK: - ProcessTerminator
// Sends SIGTERM / SIGKILL to orphaned processes with timeout-based confirmation.

struct ProcessTerminator {
    private let auditLog = Logger(subsystem: "com.justkay.therma", category: "audit")

    @discardableResult
    func terminate(pid: Int32, aggressive: Bool = false) -> Bool {
        guard pid > 0 else { return false }
        if !isProcessRunning(pid) { return true }

        var success = kill(pid, SIGTERM) == 0 || errno == ESRCH
        if success && waitForExit(pid: pid, timeout: Constants.processTerminationGraceSeconds) {
            auditLog.info("terminate pid=\(pid, privacy: .public) signal=TERM success=true")
            return true
        }

        guard aggressive else {
            auditLog.info("terminate pid=\(pid, privacy: .public) signal=TERM success=false")
            return false
        }

        success = kill(pid, SIGKILL) == 0 || errno == ESRCH
        let exited = success && waitForExit(pid: pid, timeout: 0.3)
        auditLog.info("terminate pid=\(pid, privacy: .public) signal=KILL success=\(exited, privacy: .public)")
        return exited
    }

    private func isProcessRunning(_ pid: Int32) -> Bool {
        if kill(pid, 0) == 0 { return true }
        return errno == EPERM
    }

    private func waitForExit(pid: Int32, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !isProcessRunning(pid) { return true }
            usleep(50_000)
        }
        return !isProcessRunning(pid)
    }
}
