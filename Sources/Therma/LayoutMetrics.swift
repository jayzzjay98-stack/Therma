import SwiftUI
import AppKit

enum SettingsLayoutMetrics {
    static let totalWidth: CGFloat     = 640
    static let totalHeight: CGFloat    = 470
    static let sidebarWidth: CGFloat   = 152
    static let contentWidth: CGFloat   = totalWidth
    static let contentHeight: CGFloat  = totalHeight

    static let backgroundGlowRadius: CGFloat   = 280
    static let backgroundGlowRadiusBlue: CGFloat   = 380
    static let backgroundGlowRadiusPurple: CGFloat = 300
    static let backgroundGlowRadiusWarm: CGFloat   = 200
    static let modePickerWidth: CGFloat = 200
    static let menuBarSourceListWidth: CGFloat = 188

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
