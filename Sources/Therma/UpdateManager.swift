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

    // ✏️ Change to your actual GitHub repo path before releasing.
    private let apiURL = URL(string: "https://api.github.com/repos/jayzzjay98-stack/Therma/releases/latest")!

    func resetToIdle() { state = .idle }

    func checkForUpdates() {
        state = .checking
        Task {
            do {
                let (latest, downloadURL) = try await fetchLatestRelease()
                let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                if versionIsNewer(latest, than: current) {
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
        state = .downloading
        Task {
            do {
                let zipURL = try await download(from: url)
                state = .downloaded(version: version, zipURL: zipURL)
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func installDownloaded(version: String, zipURL: URL) {
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
            let asset       = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".zip") == true }),
            let downloadURL = asset["browser_download_url"] as? String
        else { throw UpdateError.noAsset }

        return (version, downloadURL)
    }

    private func download(from url: URL) async throws -> URL {
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("Therma-update.zip")
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: tempURL, to: dest)
        return dest
    }

    private func installUpdate(from zipURL: URL) async throws {
        let workDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Therma-update-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)

        try await run("/usr/bin/unzip", ["-q", "-o", zipURL.path, "-d", workDir.path])

        let items = try FileManager.default.contentsOfDirectory(
            at: workDir, includingPropertiesForKeys: [.isDirectoryKey]
        )
        guard let newApp = items.first(where: { $0.pathExtension == "app" }) else {
            throw UpdateError.noAppBundle
        }

        try? await run("/usr/bin/xattr", ["-rd", "com.apple.quarantine", newApp.path])
        try await run("/usr/bin/codesign", ["--force", "--deep", "--sign", "-", newApp.path])

        let installPath = Bundle.main.bundleURL.path
        let script = """
        #!/bin/bash
        sleep 1.5
        rm -rf \(shellEscape(installPath))
        cp -R \(shellEscape(newApp.path)) \(shellEscape(installPath))
        /usr/bin/codesign --force --deep --sign - \(shellEscape(installPath)) 2>/dev/null
        open \(shellEscape(installPath))
        """

        let scriptPath = workDir.appendingPathComponent("replace.sh").path
        try script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o755))],
            ofItemAtPath: scriptPath
        )

        let launcher = Process()
        launcher.executableURL = URL(fileURLWithPath: "/bin/bash")
        launcher.arguments = [scriptPath]
        try launcher.run()

        NSApp.terminate(nil)
    }

    private func run(_ executable: String, _ args: [String]) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let p = Process()
            p.executableURL = URL(fileURLWithPath: executable)
            p.arguments = args
            let errPipe = Pipe()
            p.standardOutput = Pipe()
            p.standardError  = errPipe
            p.terminationHandler = { proc in
                if proc.terminationStatus == 0 {
                    cont.resume()
                } else {
                    let out = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
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

    private func versionIsNewer(_ new: String, than current: String) -> Bool {
        let parse: (String) -> [Int] = { $0.split(separator: ".").compactMap { Int($0) } }
        let n = parse(new), c = parse(current)
        let count = max(n.count, c.count)
        let nPad = n + Array(repeating: 0, count: count - n.count)
        let cPad = c + Array(repeating: 0, count: count - c.count)
        return zip(nPad, cPad).first { $0 != $1 }.map { $0 > $1 } ?? false
    }
}

// MARK: - Errors

private enum UpdateError: LocalizedError {
    case noRelease, parseError, noAsset, noAppBundle
    case processFailed(String, String)

    var errorDescription: String? {
        switch self {
        case .noRelease:              return "No release published yet."
        case .parseError:             return "Could not read release info from GitHub."
        case .noAsset:                return "Release has no downloadable package."
        case .noAppBundle:            return "Downloaded package did not contain Therma.app."
        case .processFailed(_, let o): return o.isEmpty ? "Update step failed." : o.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
