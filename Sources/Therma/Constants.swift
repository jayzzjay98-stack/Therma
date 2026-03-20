import Foundation

// MARK: - App-wide Constants

enum Constants {

    // MARK: - Memory Units
    static let bytesPerGB: Double = 1_073_741_824
    static let bytesPerMB: Double = 1_048_576
    static let bytesPerKB: Double = 1_024
    static let kbPerMB: Double    = 1_024

    // MARK: - Timer Intervals
    static let backgroundRefreshInterval: TimeInterval = 2.0
    static let foregroundRefreshInterval: TimeInterval = 3.0  // slower than background to ease CPU
    static let cpuRefreshInterval: TimeInterval        = 5.0
    // Lightweight metrics (CPU%, network) — fast kernel reads, safe at 1s
    static let systemMetricsRefreshInterval: TimeInterval = 1.0
    static let cleanTimeoutSeconds: TimeInterval       = 25.0
    static let statusMessageDismissDelay: TimeInterval = 6.0
    static let postCleanStatsDelay: TimeInterval       = 2.0
    static let memoryPressureSignalTimeout: TimeInterval = 3.0
    static let processTerminationGraceSeconds: TimeInterval = 1.2
    static let closedAppRetentionSeconds: TimeInterval = 600
    static let maxTrackedClosedApps = 24
    static let closedAppTokenMinimumLength = 4

    // MARK: - Memory Pressure Thresholds (%)
    static let pressureMediumThreshold = 60
    static let pressureHighThreshold   = 80
    static let cpuWarmThreshold: Double = 60
    static let cpuHotThreshold: Double = 80
    static let cpuCriticalThreshold: Double = 92
    static let cpuMinimumPlausibleTemperature: Double = 0
    static let cpuMaximumPlausibleTemperature: Double = 120

    // MARK: - CPU Normalization Range (°C)
    // Used by cpuNormalized() to map raw temperature onto a 0…1 scale.
    // Values below cpuNormLow are clamped to 0; above cpuNormHigh are clamped to 1.
    static let cpuNormLow: Double  = 20   // ambient/idle floor
    static let cpuNormHigh: Double = 100  // practical maximum for display purposes
    static let cpuNormRange: Double = cpuNormHigh - cpuNormLow  // 80

    // MARK: - Process Filtering
    static let minimumOrphanMemoryMB: Double = 15.0
    static let minimumDisplayMemoryMB: Double = 10.0
    static let topProcessCount = 10
    static let displayProcessCount = 5
    static let cpuVisibleSensorCount = 4
    static let cpuHistorySampleCount = 24

    // MARK: - Alert Defaults
    static let defaultRamAlertThreshold: Double = 85
    static let defaultCpuAlertThreshold: Double = 90

    // MARK: - File Permissions
    static let sudoersFilePermission = "440"

    // MARK: - UI Layout
    static let menuBarWidth: CGFloat   = 280
    static let miniRingSize: CGFloat   = 68
    static let miniRingLineWidth: CGFloat = 6
    static let segmentBarHeight: CGFloat  = 14
    static let segmentItemWidth: CGFloat  = 12
    static let segmentSpacing: CGFloat    = 1.5
    static let themeItemWidth: CGFloat    = 46
    static let themeCircleSize: CGFloat   = 36
    static let themeActiveDotSize: CGFloat = 4
    static let actionButtonHeight: CGFloat = 42
    static let processBarWidth: CGFloat    = 40
    static let defaultMenuBarIconSize: Double = 11
    static let defaultMenuBarTextSize: Double = 12
    static let minimumMenuBarIconSize: Double = 9
    static let maximumMenuBarIconSize: Double = 20
    static let minimumMenuBarTextSize: Double = 8
    static let maximumMenuBarTextSize: Double = 22

    // MARK: - Version
    // read from bundle so it always matches Info.plist
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
