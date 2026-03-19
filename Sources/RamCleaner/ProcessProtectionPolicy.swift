import Foundation

// MARK: - ProcessProtectionPolicy

struct ProcessProtectionPolicy {
    let criticalNames: Set<String> = [
        "kernel_task", "launchd", "windowserver", "loginwindow",
        "systemuiserver", "dock", "finder", "cfprefsd",
        "distnoted", "notifyd", "opendirectoryd", "securityd",
        "coreservicesd", "coreauthd", "pboard", "mds",
        "mds_stores", "usereventsagent", "syslogd", "configd",
        "powerd", "airportd", "bluetoothd", "locationd",
        "trustd", "nsurlsessiond", "lsd", "timed",
        "iconservicesagent", "sharingd", "cloudd",
        "coreduetd", "callserviceshelper", "contextstored",
        "commerced", "mediaremoted", "rapportd", "symptomsd",
        "biomeagent", "corespeechd", "siriknowledged", "suggestd",
        "intelligenceplatformd", "spotlight", "corespotlightd",
        "searchpartyd", "fseventsd", "taskgated", "sandboxd",
        "amfid", "keybagd", "accessoryd", "usernoted",
        "audiomxd", "mediaanalysisd", "calaccessd", "accountsd",
        "contactsd", "corebrightnessd", "thermalmonitord",
        "watchdogd", "displaypolicyd", "softwareupdated",
        "appstoreagent", "driverkit", "iokitd", "kernelmanagerd",
        "therma"
    ]

    let criticalPathPrefixes: [String] = [
        "/system/", "/usr/sbin/", "/usr/libexec/",
        "/usr/bin/", "/sbin/", "/bin/",
        "/library/apple/", "/library/privilegedhelpertools/"
    ]

    let helperIndicators = [
        "helper", "renderer", "crashpad", "gpu", "worker", "broker", "electron"
    ]

    let androidStudioBundleIDs: Set<String> = [
        "com.google.android.studio",
        "com.jetbrains.androidstudio"
    ]

    let androidStudioLeftoverBinaryPrefixes = [
        "qemu-system-", "emulator", "adb", "crashpad_handler", "mksdcard", "virtiofsd"
    ]

    let androidStudioLeftoverCommandFragments = [
        "/library/android/sdk/emulator/",
        "/library/android/sdk/platform-tools/adb",
        "/android studio.app/"
    ]

    func cleanedDisplayName(from raw: String) -> String {
        var name = raw
        for suffix in [" Helper (Renderer)", " Helper (GPU)", " Helper (Plugin)", " Helper"] {
            name = name.replacingOccurrences(of: suffix, with: "")
        }
        return name
    }

    func isSystemProcess(commandLine: String, baseName: String) -> Bool {
        let normalizedName = baseName.replacingOccurrences(of: ".app", with: "")
        if criticalNames.contains(normalizedName) { return true }
        if criticalPathPrefixes.contains(where: { commandLine.hasPrefix($0) }) { return true }
        if commandLine.contains("com.apple.") || commandLine.contains("/library/apple/") { return true }
        return false
    }

    func isOrphanByAppBundle(commandLine: String, active: ActiveAppSignatures) -> Bool {
        guard let range = commandLine.range(of: ".app/") else { return false }
        let appName = URL(fileURLWithPath: String(commandLine[..<range.lowerBound])).lastPathComponent
        return !active.matchesAppName(appName)
    }

    func isOrphanHelper(entry: ProcessEntry, active: ActiveAppSignatures) -> Bool {
        guard entry.ppid == 1,
              helperIndicators.contains(where: {
                  entry.commandName.contains($0) || entry.commandLine.contains($0)
              })
        else { return false }

        return !active.matchesPath(entry.commandLine)
    }

    func isAndroidStudioTool(_ entry: ProcessEntry) -> Bool {
        androidStudioLeftoverBinaryPrefixes.contains(where: { entry.commandName.hasPrefix($0) })
            || androidStudioLeftoverCommandFragments.contains(where: { entry.commandLine.contains($0) })
    }

    func isZombieAndroidStudioProcess(entry: ProcessEntry, active: ActiveAppSignatures) -> Bool {
        guard isAndroidStudioTool(entry) else { return false }
        return !androidStudioBundleIDs.contains(where: { active.bundleIDs.contains($0) })
    }
}
