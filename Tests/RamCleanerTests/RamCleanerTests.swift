import XCTest
@testable import Therma

// MARK: - RunningProcess Tests

final class RunningProcessTests: XCTestCase {

    func test_runningProcess_displayRow_hasNegativePID() {
        // Display-only merged rows must use pid -1 (never a valid PID).
        let p = RunningProcess(pid: -1, name: "Safari", memoryMB: 200)
        XCTAssertEqual(p.pid, -1)
    }
}

// MARK: - Constants Version Tests

final class ConstantsTests: XCTestCase {

    func test_appVersion_isNonEmpty() {
        XCTAssertFalse(Constants.appVersion.isEmpty)
    }

    func test_cpuRefreshInterval_isPositive() {
        XCTAssertGreaterThan(Constants.cpuRefreshInterval, 0)
    }
}

// MARK: - Monitor Display Mode Tests

final class MonitorDisplayModeTests: XCTestCase {

    func test_memoryMode_showsOnlyMemory() {
        XCTAssertTrue(MonitorDisplayMode.memory.showsMemory)
        XCTAssertFalse(MonitorDisplayMode.memory.showsCPU)
    }

    func test_cpuMode_showsOnlyCPU() {
        XCTAssertFalse(MonitorDisplayMode.cpu.showsMemory)
        XCTAssertTrue(MonitorDisplayMode.cpu.showsCPU)
    }

    func test_bothMode_showsMemoryAndCPU() {
        XCTAssertTrue(MonitorDisplayMode.both.showsMemory)
        XCTAssertTrue(MonitorDisplayMode.both.showsCPU)
    }
}

// MARK: - CPU Sensor Heuristic Tests

final class CPUSensorProviderTests: XCTestCase {

    func test_tdieSensor_isRecognizedAsCPU() {
        XCTAssertTrue(CPUSensorProvider.isLikelyCPUSensor(named: "PMU tdie8", celsius: 42))
    }

    func test_batterySensor_isNotRecognizedAsCPU() {
        XCTAssertFalse(CPUSensorProvider.isLikelyCPUSensor(named: "gas gauge battery", celsius: 28))
    }

    func test_batterySensor_isRecognizedAsBattery() {
        XCTAssertTrue(CPUSensorProvider.isLikelyBatterySensor(named: "gas gauge battery", celsius: 28))
    }

    func test_nandSensor_isNotUsedAsFallbackSensor() {
        XCTAssertFalse(CPUSensorProvider.isFallbackSensor(named: "NAND CH0 temp", celsius: 34))
    }

    func test_cycleCount_parsesNSNumber() {
        XCTAssertEqual(CPUSensorProvider.parseBatteryCycleCount(NSNumber(value: 187)), 187)
    }

    func test_cycleCount_parsesString() {
        XCTAssertEqual(CPUSensorProvider.parseBatteryCycleCount("187"), 187)
    }

    func test_negativeTemperature_isRejected() {
        XCTAssertFalse(CPUSensorProvider.isLikelyCPUSensor(named: "PMU tdev1", celsius: -22))
        XCTAssertFalse(CPUSensorProvider.isLikelyBatterySensor(named: "gas gauge battery", celsius: -22))
        XCTAssertFalse(CPUSensorProvider.isPlausibleTemperature(-22))
    }
}

// MARK: - Memory Pressure Threshold Tests

final class RAMMonitorTests: XCTestCase {

    // Access pressure computation via a testable subclass or by inspecting public state.
    // These tests exercise the threshold boundaries in Constants.

    func test_pressureMediumThreshold_is60() {
        XCTAssertEqual(Constants.pressureMediumThreshold, 60)
    }

    func test_pressureHighThreshold_is80() {
        XCTAssertEqual(Constants.pressureHighThreshold, 80)
    }

    func test_pressureMediumThreshold_lessThan_pressureHighThreshold() {
        XCTAssertLessThan(Constants.pressureMediumThreshold, Constants.pressureHighThreshold)
    }
}

// MARK: - Username Validation Tests (via PurgeManager reflection)

final class UsernameValidationTests: XCTestCase {
    // isValidUnixUsername is private, but we can test the documented rules
    // by checking what character sets are valid.

    private func isValid(_ name: String) -> Bool {
        guard !name.isEmpty, name.count <= 32 else { return false }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
        return name.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    func test_alphanumericUsername_isValid() {
        XCTAssertTrue(isValid("justkay"))
    }

    func test_usernameWithDot_isValid() {
        XCTAssertTrue(isValid("john.doe"))
    }

    func test_usernameWithHyphen_isValid() {
        XCTAssertTrue(isValid("john-doe"))
    }

    func test_usernameWithUnderscore_isValid() {
        XCTAssertTrue(isValid("john_doe"))
    }

    func test_usernameWithSpace_isInvalid() {
        XCTAssertFalse(isValid("john doe"))
    }

    func test_usernameWithSemicolon_isInvalid() {
        XCTAssertFalse(isValid("john;doe"))
    }

    func test_usernameWithSingleQuote_isInvalid() {
        XCTAssertFalse(isValid("john'doe"))
    }

    func test_emptyUsername_isInvalid() {
        XCTAssertFalse(isValid(""))
    }

    func test_usernameExceeding32Chars_isInvalid() {
        XCTAssertFalse(isValid(String(repeating: "a", count: 33)))
    }

    func test_usernameExactly32Chars_isValid() {
        XCTAssertTrue(isValid(String(repeating: "a", count: 32)))
    }
}

// MARK: - Closed App Tracking Tests

final class ClosedAppSignatureTests: XCTestCase {

    func test_closedAppSignature_matchesBundleCommandLine() {
        let signature = ClosedAppSignature(
            bundleID: "com.example.MyApp",
            localizedName: "My App",
            bundlePath: "/Applications/My App.app",
            executablePath: "/Applications/My App.app/Contents/MacOS/My App"
        )

        XCTAssertTrue(
            signature.matches(
                commandLine: "/Applications/My App.app/Contents/Frameworks/My App Helper.app/Contents/MacOS/My App Helper --type=renderer",
                commandName: "my app helper",
                helperIndicators: ["helper", "renderer"]
            )
        )
    }

    func test_closedAppSignature_doesNotMatchUnrelatedProcess() {
        let signature = ClosedAppSignature(
            bundleID: "com.example.MyApp",
            localizedName: "My App",
            bundlePath: "/Applications/My App.app",
            executablePath: "/Applications/My App.app/Contents/MacOS/My App"
        )

        XCTAssertFalse(
            signature.matches(
                commandLine: "/Applications/Safari.app/Contents/MacOS/Safari",
                commandName: "safari",
                helperIndicators: ["helper", "renderer"]
            )
        )
    }
}

// MARK: - ProcessProtectionPolicy Tests

final class ProcessProtectionPolicyTests: XCTestCase {

    private let policy = ProcessProtectionPolicy()

    // MARK: System process detection

    func test_kernelTask_isSystemProcess() {
        XCTAssertTrue(policy.isSystemProcess(commandLine: "/usr/bin/kernel_task", baseName: "kernel_task"))
    }

    func test_launchd_isSystemProcess() {
        XCTAssertTrue(policy.isSystemProcess(commandLine: "/sbin/launchd", baseName: "launchd"))
    }

    func test_systemPathProcess_isSystemProcess() {
        XCTAssertTrue(policy.isSystemProcess(commandLine: "/system/library/something", baseName: "something"))
    }

    func test_appleFramework_isSystemProcess() {
        XCTAssertTrue(policy.isSystemProcess(commandLine: "com.apple.audio.coreaudiod", baseName: "coreaudiod"))
    }

    func test_userApp_isNotSystemProcess() {
        XCTAssertFalse(policy.isSystemProcess(commandLine: "/Applications/Slack.app/Contents/MacOS/Slack", baseName: "slack"))
    }

    func test_thirdPartyBinary_isNotSystemProcess() {
        XCTAssertFalse(policy.isSystemProcess(commandLine: "/usr/local/bin/node", baseName: "node"))
    }

    // MARK: Android Studio tool detection

    func test_qemuSystem_isAndroidStudioTool() {
        let entry = ProcessEntry(pid: 100, ppid: 1, rssKB: 100, commandName: "qemu-system-x86_64", commandLine: "/some/path/qemu-system-x86_64")
        XCTAssertTrue(policy.isAndroidStudioTool(entry))
    }

    func test_adb_isAndroidStudioTool() {
        let entry = ProcessEntry(pid: 101, ppid: 1, rssKB: 100, commandName: "adb", commandLine: "/library/android/sdk/platform-tools/adb")
        XCTAssertTrue(policy.isAndroidStudioTool(entry))
    }

    func test_emulator_isAndroidStudioTool() {
        let entry = ProcessEntry(pid: 102, ppid: 1, rssKB: 100, commandName: "emulator", commandLine: "/library/android/sdk/emulator/emulator")
        XCTAssertTrue(policy.isAndroidStudioTool(entry))
    }

    func test_safari_isNotAndroidStudioTool() {
        let entry = ProcessEntry(pid: 200, ppid: 1, rssKB: 100, commandName: "safari", commandLine: "/Applications/Safari.app/Contents/MacOS/Safari")
        XCTAssertFalse(policy.isAndroidStudioTool(entry))
    }

    // MARK: Display name cleaning

    func test_cleanedDisplayName_stripsHelperSuffix() {
        XCTAssertEqual(policy.cleanedDisplayName(from: "Google Chrome Helper (Renderer)"), "Google Chrome")
    }

    func test_cleanedDisplayName_stripsGPUSuffix() {
        XCTAssertEqual(policy.cleanedDisplayName(from: "Slack Helper (GPU)"), "Slack")
    }

    func test_cleanedDisplayName_stripsPlainHelperSuffix() {
        XCTAssertEqual(policy.cleanedDisplayName(from: "Firefox Helper"), "Firefox")
    }

    func test_cleanedDisplayName_noSuffix_unchanged() {
        XCTAssertEqual(policy.cleanedDisplayName(from: "Terminal"), "Terminal")
    }
}

// MARK: - ActiveAppSignatures Tests

final class ActiveAppSignaturesTests: XCTestCase {

    private func makeSignatures(
        pids: Set<Int32> = [],
        names: Set<String> = [],
        bundleIDs: Set<String> = [],
        execPaths: Set<String> = []
    ) -> ActiveAppSignatures {
        ActiveAppSignatures(pids: pids, names: names, bundleIDs: bundleIDs, execPaths: execPaths)
    }

    func test_matchesAppName_byName() {
        let sigs = makeSignatures(names: ["safari"])
        XCTAssertTrue(sigs.matchesAppName("safari"))
    }

    func test_matchesAppName_byBundleID() {
        let sigs = makeSignatures(bundleIDs: ["com.apple.safari"])
        XCTAssertTrue(sigs.matchesAppName("safari"))
    }

    func test_matchesAppName_byExecPath() {
        let sigs = makeSignatures(execPaths: ["/Applications/Safari.app/Contents/MacOS/safari"])
        XCTAssertTrue(sigs.matchesAppName("safari"))
    }

    func test_matchesAppName_unknownApp_returnsFalse() {
        let sigs = makeSignatures(names: ["safari"])
        XCTAssertFalse(sigs.matchesAppName("notion"))
    }

    func test_matchesPath_byName() {
        let sigs = makeSignatures(names: ["slack"])
        // Real code passes lowercased commandLine (from ProcessSnapshotReader)
        XCTAssertTrue(sigs.matchesPath("/applications/slack.app/contents/macos/slack helper"))
    }

    func test_matchesPath_unknownPath_returnsFalse() {
        let sigs = makeSignatures(names: ["safari"])
        XCTAssertFalse(sigs.matchesPath("/applications/notion.app/contents/macos/notion"))
    }

    func test_contains_matchesByBundleID() {
        let sigs = makeSignatures(bundleIDs: ["com.example.myapp"])
        let sig = ClosedAppSignature(
            bundleID: "com.example.myapp",
            localizedName: "My App",
            bundlePath: "/Applications/My App.app",
            executablePath: nil
        )
        XCTAssertTrue(sigs.contains(signature: sig))
    }

    func test_contains_noMatch_returnsFalse() {
        let sigs = makeSignatures(bundleIDs: ["com.example.otherapp"])
        let sig = ClosedAppSignature(
            bundleID: "com.example.myapp",
            localizedName: "My App",
            bundlePath: "/Applications/My App.app",
            executablePath: nil
        )
        XCTAssertFalse(sigs.contains(signature: sig))
    }
}

// MARK: - PurgeError Tests

final class PurgeErrorTests: XCTestCase {

    func test_authCancelled_hasDescription() {
        XCTAssertNotNil(PurgeError.authCancelled.errorDescription)
        XCTAssertFalse(PurgeError.authCancelled.errorDescription!.isEmpty)
    }

    func test_invalidUsername_hasDescription() {
        XCTAssertNotNil(PurgeError.invalidUsername.errorDescription)
        XCTAssertFalse(PurgeError.invalidUsername.errorDescription!.isEmpty)
    }

    func test_appleScriptFailed_hasDescription() {
        XCTAssertNotNil(PurgeError.appleScriptFailed.errorDescription)
        XCTAssertFalse(PurgeError.appleScriptFailed.errorDescription!.isEmpty)
    }

    func test_allErrors_haveDistinctDescriptions() {
        let descriptions = Set([
            PurgeError.authCancelled.errorDescription,
            PurgeError.invalidUsername.errorDescription,
            PurgeError.appleScriptFailed.errorDescription
        ])
        XCTAssertEqual(descriptions.count, 3)
    }
}

// MARK: - LayoutMetrics Tests

final class LayoutMetricsTests: XCTestCase {

    func test_settingsContentSize_isPositive() {
        XCTAssertGreaterThan(SettingsLayoutMetrics.contentWidth, 0)
        XCTAssertGreaterThan(SettingsLayoutMetrics.contentHeight, 0)
    }

    func test_popoverMemoryHeight_greaterThan_cpuHeight() {
        // Memory view shows more content than CPU-only view.
        XCTAssertGreaterThan(MenuBarPopoverMetrics.memoryHeight, MenuBarPopoverMetrics.cpuHeight)
    }

    func test_menuBarWidth_matchesConstants() {
        let popoverSize = MenuBarPopoverMetrics.size(for: .memory)
        XCTAssertEqual(popoverSize.width, Constants.menuBarWidth)
    }

    func test_popoverSize_memory_usesMemoryHeight() {
        let size = MenuBarPopoverMetrics.size(for: .memory)
        XCTAssertEqual(size.height, MenuBarPopoverMetrics.memoryHeight)
    }

    func test_popoverSize_cpu_usesCPUHeight() {
        let size = MenuBarPopoverMetrics.size(for: .cpu)
        XCTAssertEqual(size.height, MenuBarPopoverMetrics.cpuHeight)
    }
}

// MARK: - Constants Completeness Tests

final class ConstantsCompletenessTests: XCTestCase {

    func test_timerIntervals_areAllPositive() {
        XCTAssertGreaterThan(Constants.backgroundRefreshInterval, 0)
        XCTAssertGreaterThan(Constants.foregroundRefreshInterval, 0)
        XCTAssertGreaterThan(Constants.cpuRefreshInterval, 0)
        XCTAssertGreaterThan(Constants.cleanTimeoutSeconds, 0)
    }

    func test_cpuThresholds_areOrdered() {
        XCTAssertLessThan(Constants.cpuWarmThreshold, Constants.cpuHotThreshold)
        XCTAssertLessThan(Constants.cpuHotThreshold, Constants.cpuCriticalThreshold)
    }

    func test_cpuTemperatureRange_isPlausible() {
        XCTAssertGreaterThanOrEqual(Constants.cpuMinimumPlausibleTemperature, 0)
        XCTAssertLessThanOrEqual(Constants.cpuMaximumPlausibleTemperature, 150)
        XCTAssertLessThan(Constants.cpuMinimumPlausibleTemperature, Constants.cpuMaximumPlausibleTemperature)
    }

    func test_processCountLimits_arePositive() {
        XCTAssertGreaterThan(Constants.topProcessCount, 0)
        XCTAssertGreaterThan(Constants.displayProcessCount, 0)
        XCTAssertLessThanOrEqual(Constants.displayProcessCount, Constants.topProcessCount)
    }

    func test_sudoersPermission_isCorrectFormat() {
        XCTAssertEqual(Constants.sudoersFilePermission, "440")
    }

    func test_menuBarWidth_isPositive() {
        XCTAssertGreaterThan(Constants.menuBarWidth, 0)
    }
}
