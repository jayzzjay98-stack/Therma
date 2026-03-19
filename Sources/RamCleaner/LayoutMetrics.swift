import SwiftUI
import AppKit

enum SettingsLayoutMetrics {
    static let totalWidth: CGFloat     = 540
    static let totalHeight: CGFloat    = 480
    static let sidebarWidth: CGFloat   = 158
    static let contentWidth: CGFloat   = totalWidth  // used for window frame
    static let contentHeight: CGFloat  = totalHeight

    static let backgroundGlowRadius: CGFloat = 280
    static let modePickerWidth: CGFloat = 200

    static let contentSize = NSSize(width: totalWidth, height: totalHeight)
    static let windowFrameRect = NSRect(x: 0, y: 0, width: totalWidth, height: totalHeight)
}

enum MenuBarPopoverMetrics {
    static let memoryHeight: CGFloat = 520
    static let cpuHeight: CGFloat    = 485

    static func size(for mode: MonitorDisplayMode) -> NSSize {
        NSSize(
            width: Constants.menuBarWidth,
            height: mode == .memory ? memoryHeight : cpuHeight
        )
    }
}
