import Foundation

final class ProcessManager: @unchecked Sendable {
    private let snapshotReader: ProcessSnapshotReader
    private let activeAppBuilder: ActiveAppSignatureBuilder
    private let detector: LeftoverProcessDetector
    private let terminator: ProcessTerminator
    private let protectionPolicy: ProcessProtectionPolicy

    init(
        snapshotReader: ProcessSnapshotReader = ProcessSnapshotReader(),
        activeAppBuilder: ActiveAppSignatureBuilder = ActiveAppSignatureBuilder(),
        detector: LeftoverProcessDetector = LeftoverProcessDetector(),
        terminator: ProcessTerminator = ProcessTerminator(),
        protectionPolicy: ProcessProtectionPolicy = ProcessProtectionPolicy()
    ) {
        self.snapshotReader = snapshotReader
        self.activeAppBuilder = activeAppBuilder
        self.detector = detector
        self.terminator = terminator
        self.protectionPolicy = protectionPolicy
    }

    func fetchTopProcesses(
        limit: Int = Constants.displayProcessCount,
        completion: @escaping ([RunningProcess]) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            completion(
                self.snapshotReader.readTopProcesses(
                    limit: limit,
                    nameCleaner: self.protectionPolicy.cleanedDisplayName(from:)
                )
            )
        }
    }

    func findLeftoverProcesses(
        recentlyClosedApps: [ClosedAppSignature],
        completion: @escaping ([RunningProcess]) -> Void
    ) {
        DispatchQueue.main.async {
            let active = self.activeAppBuilder.build()
            DispatchQueue.global(qos: .userInitiated).async {
                completion(
                    self.detector.detectLeftovers(
                        active: active,
                        recentlyClosedApps: recentlyClosedApps
                    )
                )
            }
        }
    }

    @discardableResult
    func terminate(pid: Int32, aggressive: Bool = false) -> Bool {
        terminator.terminate(pid: pid, aggressive: aggressive)
    }
}
