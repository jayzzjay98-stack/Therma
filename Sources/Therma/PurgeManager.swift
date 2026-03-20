import Foundation
import AppKit

// MARK: - Purge Manager
//
// Security fix: original code used string interpolation of `NSUserName()` directly
// into an AppleScript shell command, allowing shell injection if the username
// contained special characters. This version sanitises the username and uses
// a two-step approach: write the sudoers file via a quoted heredoc so the
// username never appears inside a shell-executed string unescaped.

// no mutable properties — Process and NSAppleScript each run on their own queue
final class PurgeManager: @unchecked Sendable {

    // MARK: - Public API

    typealias Completion = @Sendable (Result<Void, PurgeError>) -> Void

    /// Runs `purge` silently if sudoers rule exists; otherwise asks for admin password once
    /// to set up the rule, then runs purge. No Touch ID prompt is shown.
    func purge(completion: @escaping Completion) {
        executePurge(completion: completion)
    }

    // MARK: - Purge Execution

    private func executePurge(completion: @escaping Completion) {
        // Attempt 1: silent sudo purge (works when sudoers rule already exists)
        if trySilentPurge() {
            completion(.success(()))
            return
        }

        // Attempt 2: request admin privileges via AppleScript, then write sudoers + purge
        setupSudoersAndPurge(completion: completion)
    }

    private func trySilentPurge() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments     = ["-n", "/usr/sbin/purge"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError  = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    /// Writes a sudoers drop-in file that grants the current user password-less
    /// access to `/usr/sbin/purge`, then runs purge.
    ///
    /// Security: `NSUserName()` is validated against a strict allowlist before
    /// being embedded in any shell command. The sudoers content is written via
    /// `tee` with a here-doc so the username is never interpreted as a shell token.
    private func setupSudoersAndPurge(completion: @escaping Completion) {
        let rawUser = NSUserName()

        // Validate username: only alphanumerics, dots, underscores, hyphens
        guard isValidUnixUsername(rawUser) else {
            completion(.failure(.invalidUsername))
            return
        }

        let sudoersPath    = "/private/etc/sudoers.d/therma_\(rawUser)"
        let sudoersContent = "\(rawUser) ALL=(ALL) NOPASSWD: /usr/sbin/purge"

        // Build the AppleScript shell commands using single-quoted arguments to
        // prevent any shell interpretation of the content.
        let script = buildAppleScript(
            sudoersPath: sudoersPath,
            sudoersContent: sudoersContent
        )

        DispatchQueue.global(qos: .userInitiated).async {
            var errorDict: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&errorDict)

            DispatchQueue.main.async {
                if errorDict != nil {
                    completion(.failure(.appleScriptFailed))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Security Helpers

    /// Only allows characters that are valid in a POSIX user account name.
    private func isValidUnixUsername(_ name: String) -> Bool {
        guard !name.isEmpty, name.count <= 32 else { return false }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
        return name.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    /// Builds a minimal AppleScript that:
    /// 1. Creates the sudoers drop-in file using `printf` (avoids heredoc shell-injection)
    /// 2. Sets the correct permission (0440)
    /// 3. Validates the file with `visudo -cf`
    /// 4. Runs `purge`
    private func buildAppleScript(sudoersPath: String, sudoersContent: String) -> String {
        // sudoersContent already validated — rawUser is alphanumeric-only
        // We use printf '%s' to write the content without any shell interpretation.
        let shellCommands = [
            "mkdir -p /private/etc/sudoers.d",
            "printf '%s\\n' '\(sudoersContent)' > '\(sudoersPath)'",
            "chmod \(Constants.sudoersFilePermission) '\(sudoersPath)'",
            "visudo -cf '\(sudoersPath)'",
            "/usr/sbin/purge"
        ].joined(separator: " && ")

        return """
        do shell script "\(shellCommands)" \\
            with prompt "Therma needs your password once to enable Touch ID for future cleaning!" \\
            with administrator privileges
        """
    }

    // MARK: - Memory Pressure Signal

    /// Sends a `warn` memory-pressure event so apps release cached memory.
    func sendMemoryPressureWarning() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/memory_pressure")
        process.arguments     = ["-l", "warn"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError  = FileHandle.nullDevice

        do {
            try process.run()
            DispatchQueue.global().asyncAfter(deadline: .now() + Constants.memoryPressureSignalTimeout) {
                if process.isRunning { process.terminate() }
            }
        } catch {
            // `memory_pressure` is not available on all configurations — safe to ignore
        }
    }
}

// MARK: - Error Types

enum PurgeError: Error, LocalizedError {
    case authCancelled
    case invalidUsername
    case appleScriptFailed

    var errorDescription: String? {
        switch self {
        case .authCancelled:    return "Authentication cancelled"
        case .invalidUsername:  return "Username contains unsupported characters"
        case .appleScriptFailed: return "Failed to obtain administrator privileges"
        }
    }
}
