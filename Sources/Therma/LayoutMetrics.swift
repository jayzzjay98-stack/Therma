import SwiftUI
import AppKit

enum SettingsLayoutMetrics {
    static let totalWidth: CGFloat     = 900
    static let totalHeight: CGFloat    = 600
    static let sidebarWidth: CGFloat   = 152
    static let contentWidth: CGFloat   = totalWidth
    static let contentHeight: CGFloat  = totalHeight
    static let dashboardCardHeight: CGFloat = 238
    static let dashboardGridSpacing: CGFloat = 14
    static let dashboardCanvasHeight: CGFloat = dashboardCardHeight * Constants.dashboardRowCount + dashboardGridSpacing

    static let backgroundGlowRadius: CGFloat       = 280
    static let backgroundGlowRadiusBlue: CGFloat   = 600
    static let backgroundGlowRadiusPurple: CGFloat = 520
    static let backgroundGlowRadiusWarm: CGFloat   = 200
    static let modePickerWidth: CGFloat = 200
    static let menuBarSourceListWidth: CGFloat = 196

    static let contentSize = NSSize(width: totalWidth, height: totalHeight)
    static let windowFrameRect = NSRect(x: 0, y: 0, width: totalWidth, height: totalHeight)
}

enum MenuBarPopoverMetrics {
    static let memoryHeight: CGFloat = 580
    static let cpuHeight: CGFloat    = 485

    static func size(for mode: MonitorDisplayMode) -> NSSize {
        NSSize(
            width: Constants.menuBarWidth,
            height: mode == .memory ? memoryHeight : cpuHeight
        )
    }
}
