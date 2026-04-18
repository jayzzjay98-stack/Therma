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
    static let gpuRefreshInterval: TimeInterval        = 2.0
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
    static let maxPercentage: Double = 100 // 100 % — used for fraction-to-percent conversions

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
    static let segmentHeightDropFactor: Double = 0.8
    static let actionButtonHeight: CGFloat = 42
    static let processBarWidth: CGFloat    = 40
    static let defaultMenuBarIconSize: Double = 11
    static let defaultMenuBarTextSize: Double = 12
    static let minimumMenuBarIconSize: Double = 9
    static let maximumMenuBarIconSize: Double = 20
    static let minimumMenuBarTextSize: Double = 8
    static let maximumMenuBarTextSize: Double = 22

    // MARK: - Thermal Trace Bar Sizing
    static let traceBarMinHeight: CGFloat  = 12   // minimum bar height in px
    static let traceBarHeightRange: CGFloat = 40  // height range above minimum

    // MARK: - Dashboard Layout
    static let dashboardRowCount: CGFloat = 2     // rows in the dashboard card grid

    // MARK: - Version
    // read from bundle so it always matches Info.plist
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - Thermal Colour Scale
//
// Single source of truth for the five heat-band colours used in both the
// menu-bar popover and the settings dashboard. Callers keep a thin wrapper
// (private func thermalColor(for:)) so call-sites stay unchanged.

import SwiftUI

enum ThermalPalette {
    // Colour bands (low → high temperature)
    static let cool     = Color(red: 0.30, green: 0.82, blue: 1.00)
    static let warm     = Color(red: 0.38, green: 0.92, blue: 0.68)
    static let hot      = Color(red: 0.98, green: 0.85, blue: 0.28)
    static let veryHot  = Color(red: 1.00, green: 0.58, blue: 0.18)
    static let critical = Color(red: 1.00, green: 0.28, blue: 0.32)

    // Display thresholds (°C) — separate from alert thresholds in Constants
    static let warmThreshold:     Double = 50
    static let hotThreshold:      Double = 65
    static let veryHotThreshold:  Double = 78
    static let criticalThreshold: Double = 88

    static func color(for celsius: Double) -> Color {
        switch celsius {
        case ..<warmThreshold:     return cool
        case ..<hotThreshold:      return warm
        case ..<veryHotThreshold:  return hot
        case ..<criticalThreshold: return veryHot
        default:                   return critical
        }
    }
}
