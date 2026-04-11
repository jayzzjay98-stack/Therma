import Foundation
import AppKit

// MARK: - In-App Updater (GitHub Releases)
//
// Checks the latest GitHub Release for this project, downloads the .zip asset,
// unpacks it, and hot-swaps the running app — all without Sparkle or an appcast server.
//
// Release requirement: each GitHub Release must attach a zip named "Therma-<version>.zip"
// containing "Therma.app" at its root.

@MainActor
final class UpdateManager: ObservableObject {

    enum State {
        case idle
        case checking
        case upToDate
        case available(version: String, downloadURL: String)
        case downloading
        case downloaded(version: String, zipURL: URL)
        case installing
        case failed(String)
    }

    @Published var state: State = .idle
    @Published var downloadProgress: Double?

    // ✏️ Change to your actual GitHub repo path before releasing.
    private let apiURL = URL(string: "https://api.github.com/repos/jayzzjay98-stack/Therma/releases/latest")!
    private let expectedBundleName = "Therma.app"
    private var activeDownloadController: ReleaseDownloadController?

    func resetToIdle() {
        downloadProgress = nil
        state = .idle
    }

    func checkForUpdates() {
        downloadProgress = nil
        state = .checking
        Task {
            do {
                let (latest, downloadURL) = try await fetchLatestRelease()
                let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                if Self.versionIsNewer(latest, than: current) {
                    state = .available(version: latest, downloadURL: downloadURL)
                } else {
                    state = .upToDate
                }
            } catch UpdateError.noRelease {
                state = .upToDate
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func startDownload(version: String, downloadURL: String) {
        guard
            let url = URL(string: downloadURL),
            url.scheme == "https",
            let host = url.host,
            host == "github.com" || host.hasSuffix(".githubusercontent.com")
        else {
            state = .failed("Untrusted download URL.")
            return
        }
        downloadProgress = 0
        state = .downloading
        let controller = ReleaseDownloadController()
        activeDownloadController = controller
        Task {
            do {
                let zipURL = try await controller.download(from: url) { [weak self] progress in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.downloadProgress = progress
                    }
                }
                guard activeDownloadController === controller else { return }
                activeDownloadController = nil
                downloadProgress = nil
                state = .downloaded(version: version, zipURL: zipURL)
            } catch {
                guard activeDownloadController === controller else { return }
                activeDownloadController = nil
                downloadProgress = nil
                state = .failed(error.localizedDescription)
            }
        }
    }

    func installDownloaded(version: String, zipURL: URL) {
        downloadProgress = nil
        state = .installing
        Task {
            do {
                try await installUpdate(from: zipURL)
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    // MARK: - Private

    private func fetchLatestRelease() async throws -> (version: String, downloadURL: String) {
        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 404 {
            throw UpdateError.noRelease
        }

        guard
            let json    = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let tagName = json["tag_name"] as? String
        else { throw UpdateError.parseError }

        let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName

        let assets = json["assets"] as? [[String: Any]] ?? []
        guard
            let downloadURL = Self.preferredZipAssetDownloadURL(in: assets, version: version)
        else { throw UpdateError.noAsset }

        return (version, downloadURL)
    }

    private func installUpdate(from zipURL: URL) async throws {
        let workDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Therma-update-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)

        try await run("/usr/bin/ditto", ["-x", "-k", "--noqtn", zipURL.path, workDir.path])

        let newApp = try Self.findAppBundle(in: workDir, named: expectedBundleName)
        try Self.sanitizeExtractedBundle(at: newApp)
        guard Self.bundleLooksValid(at: newApp, expectedName: expectedBundleName) else {
            throw UpdateError.invalidAppBundle
        }

        // Verify signature first — re-sign with ad-hoc if the downloaded bundle is unsigned.
        // Quarantine is only removed AFTER we have confirmed a valid signature, so Gatekeeper
        // cannot be bypassed on an unverified bundle.
        do {
            try await verifySignature(of: newApp)
        } catch {
            try await run("/usr/bin/codesign", ["--force", "--deep", "--sign", "-", newApp.path])
            try await verifySignature(of: newApp)
        }

        // Safe to strip quarantine now — signature is verified above.
        try? await run("/usr/bin/xattr", ["-rd", "com.apple.quarantine", newApp.path])

        let installPath = Bundle.main.bundleURL
        let scriptURL = try writeInstallScript(
            replacing: installPath,
            with: newApp,
            workDir: workDir
        )
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o755))],
            ofItemAtPath: scriptURL.path
        )

        // Run install script at lower priority so it doesn't stutter the system
        let launcher = Process()
        launcher.executableURL = URL(fileURLWithPath: "/usr/bin/nice")
        launcher.arguments = ["-n", "15", "/bin/bash", scriptURL.path]
        try launcher.run()

        NSApp.terminate(nil)
    }

    private func verifySignature(of appURL: URL) async throws {
        try await run("/usr/bin/codesign", ["--verify", "--deep", "--strict", appURL.path])
    }

    private func writeInstallScript(replacing installURL: URL, with newApp: URL, workDir: URL) throws -> URL {
        let installPath = installURL.path
        let parentURL = installURL.deletingLastPathComponent()
        let stagedURL = parentURL.appendingPathComponent("\(installURL.lastPathComponent).update")
        let backupURL = parentURL.appendingPathComponent("\(installURL.lastPathComponent).backup")
        let pid = ProcessInfo.processInfo.processIdentifier
        let script = """
        #!/bin/bash
        set -euo pipefail
        # Lower I/O and CPU priority so the install doesn't stutter the system
        renice -n 15 $$ >/dev/null 2>&1 || true

        INSTALL_PATH=\(shellEscape(installPath))
        SOURCE_PATH=\(shellEscape(newApp.path))
        STAGED_PATH=\(shellEscape(stagedURL.path))
        BACKUP_PATH=\(shellEscape(backupURL.path))
        WORK_DIR=\(shellEscape(workDir.path))
        PARENT_PID=\(pid)

        cleanup() {
          if [ -d "$BACKUP_PATH" ] && [ ! -d "$INSTALL_PATH" ]; then
            mv "$BACKUP_PATH" "$INSTALL_PATH"
          fi
          rm -rf "$STAGED_PATH"
        }
        trap cleanup EXIT

        # Wait for the app to exit cleanly
        for i in {1..20}; do
            if ! kill -0 $PARENT_PID 2>/dev/null; then
                break
            fi
            sleep 0.5
        done
        # Force kill if still running
        kill -9 $PARENT_PID 2>/dev/null || true

        rm -rf "$STAGED_PATH" "$BACKUP_PATH"
        # Use ditto which preserves the ad-hoc signature already applied before this script runs
        /usr/bin/ditto "$SOURCE_PATH" "$STAGED_PATH"
        /usr/bin/xattr -rd com.apple.quarantine "$STAGED_PATH" >/dev/null 2>&1 || true

        if [ -d "$INSTALL_PATH" ]; then
          mv "$INSTALL_PATH" "$BACKUP_PATH"
        fi
        mv "$STAGED_PATH" "$INSTALL_PATH"

        trap - EXIT
        open "$INSTALL_PATH"
        
        # Clean up in background
        rm -rf "$BACKUP_PATH" "$WORK_DIR" &
        """

        let scriptURL = workDir.appendingPathComponent("replace.sh")
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        return scriptURL
    }

    private func run(_ executable: String, _ args: [String]) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let p = Process()
            p.executableURL = URL(fileURLWithPath: executable)
            p.arguments = args
            let outputPipe = Pipe()
            p.standardOutput = outputPipe
            p.standardError  = outputPipe
            
            let q = DispatchQueue(label: "proc-output")
            var outputData = Data()
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let available = handle.availableData
                guard !available.isEmpty else { return }
                q.sync { outputData.append(available) }
            }

            p.terminationHandler = { proc in
                outputPipe.fileHandleForReading.readabilityHandler = nil
                let out = q.sync { String(data: outputData, encoding: .utf8) ?? "" }
                if proc.terminationStatus == 0 {
                    cont.resume()
                } else {
                    cont.resume(throwing: UpdateError.processFailed(executable, out))
                }
            }
            do    { try p.run() }
            catch { cont.resume(throwing: error) }
        }
    }

    private func shellEscape(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    nonisolated static func versionIsNewer(_ new: String, than current: String) -> Bool {
        let parse: (String) -> [Int] = { $0.split(separator: ".").compactMap { Int($0) } }
        let n = parse(new), c = parse(current)
        let count = max(n.count, c.count)
        let nPad = n + Array(repeating: 0, count: count - n.count)
        let cPad = c + Array(repeating: 0, count: count - c.count)
        return zip(nPad, cPad).first { $0 != $1 }.map { $0 > $1 } ?? false
    }

    nonisolated static func normalizedDownloadProgress(totalBytesWritten: Int64, expectedTotalBytes: Int64) -> Double? {
        guard expectedTotalBytes > 0 else { return nil }
        let progress = Double(totalBytesWritten) / Double(expectedTotalBytes)
        return min(max(progress, 0), 1)
    }

    nonisolated static func preferredZipAssetDownloadURL(in assets: [[String: Any]], version: String) -> String? {
        let zipAssets = assets.compactMap { asset -> (name: String, url: String)? in
            guard
                let name = asset["name"] as? String,
                name.hasSuffix(".zip"),
                let url = asset["browser_download_url"] as? String
            else { return nil }
            return (name, url)
        }

        if let exactMatch = zipAssets.first(where: { $0.name == "Therma-\(version).zip" }) {
            return exactMatch.url
        }

        if zipAssets.count == 1 {
            return zipAssets[0].url
        }

        return nil
    }

    nonisolated static func findAppBundle(in directory: URL, named expectedName: String) throws -> URL {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsPackageDescendants],
            errorHandler: nil
        ) else {
            throw UpdateError.noAppBundle
        }

        var exactMatches: [URL] = []
        var appMatches: [URL] = []

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "app" else { continue }
            appMatches.append(fileURL)
            if fileURL.lastPathComponent == expectedName {
                exactMatches.append(fileURL)
            }
        }

        let candidates = exactMatches.isEmpty ? appMatches : exactMatches
        guard candidates.count == 1, let match = candidates.first else {
            throw candidates.isEmpty ? UpdateError.noAppBundle : UpdateError.ambiguousAppBundle
        }
        return match
    }

    nonisolated static func sanitizeExtractedBundle(at appURL: URL) throws {
        let fileManager = FileManager.default
        let relativePaths = try fileManager.subpathsOfDirectory(atPath: appURL.path)

        for relativePath in relativePaths {
            let fileURL = appURL.appendingPathComponent(relativePath)
            let name = fileURL.lastPathComponent
            if name == ".DS_Store" || name.hasPrefix("._") {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }

    nonisolated static func bundleLooksValid(at appURL: URL, expectedName: String = "Therma.app") -> Bool {
        let fileManager = FileManager.default
        guard appURL.lastPathComponent == expectedName else { return false }

        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        let infoPlistURL = contentsURL.appendingPathComponent("Info.plist")
        guard fileManager.fileExists(atPath: infoPlistURL.path) else { return false }
        guard let bundle = Bundle(url: appURL) else { return false }
        guard let executableName = bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as? String,
              !executableName.isEmpty else { return false }

        let executableURL = contentsURL
            .appendingPathComponent("MacOS", isDirectory: true)
            .appendingPathComponent(executableName)
        return fileManager.fileExists(atPath: executableURL.path)
    }
}

private final class ReleaseDownloadController: NSObject, URLSessionDownloadDelegate {
    private var continuation: CheckedContinuation<URL, Error>?
    private var progressHandler: ((Double) -> Void)?
    private var finished = false

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    func download(from url: URL, progress: @escaping (Double) -> Void) async throws -> URL {
        progressHandler = progress

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let task = session.downloadTask(with: url)
            task.resume()
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard
            let progress = UpdateManager.normalizedDownloadProgress(
                totalBytesWritten: totalBytesWritten,
                expectedTotalBytes: totalBytesExpectedToWrite
            )
        else { return }

        progressHandler?(progress)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard !finished, let continuation else { return }
        finished = true

        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("Therma-update-\(UUID().uuidString).zip")
        try? FileManager.default.removeItem(at: dest)

        do {
            try FileManager.default.moveItem(at: location, to: dest)
            continuation.resume(returning: dest)
        } catch {
            continuation.resume(throwing: error)
        }

        self.continuation = nil
        progressHandler = nil
        session.finishTasksAndInvalidate()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard !finished, let error, let continuation else { return }
        finished = true
        self.continuation = nil
        progressHandler = nil
        continuation.resume(throwing: error)
        session.invalidateAndCancel()
    }
}

// MARK: - Errors

private enum UpdateError: LocalizedError {
    case noRelease, parseError, noAsset, noAppBundle, ambiguousAppBundle, invalidAppBundle
    case processFailed(String, String)

    var errorDescription: String? {
        switch self {
        case .noRelease:              return "No release published yet."
        case .parseError:             return "Could not read release info from GitHub."
        case .noAsset:                return "Release has no downloadable package."
        case .noAppBundle:            return "Downloaded package did not contain Therma.app."
        case .ambiguousAppBundle:     return "Downloaded package contained multiple app bundles."
        case .invalidAppBundle:       return "Downloaded app bundle is incomplete."
        case .processFailed(_, let o): return o.isEmpty ? "Update step failed." : o.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
