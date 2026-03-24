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

    // MARK: - Pane Hero Banner
    static let paneHeroHeight: CGFloat        = 122   // .frame(height:) for SettingsPaneHero banners
    static let paneHeroGlowRadius: CGFloat    = 180   // RadialGradient endRadius inside SettingsPaneHero

    // MARK: - Menu Bar Pane
    static let menuBarModulePanelWidth: CGFloat = 280  // fixed width of the modules list panel

    // MARK: - About Pane
    static let aboutHeroBannerHeight: CGFloat = 156   // top hero card height on About pane
    static let aboutGlowRadius: CGFloat       = 220   // RadialGradient endRadius on About hero
    static let aboutInfoPanelHeight: CGFloat  = 244   // fixed minHeight/maxHeight of about info panels

    // MARK: - Dashboard Chart Elements
    static let dashboardMiniChartHeight: CGFloat = 124   // SettingsGlowingAreaChart height in dashboard cards
    static let dashboardGaugeSizeLarge: CGFloat  = 136   // large circular gauge (RAM usage)
    static let dashboardGaugeSizeSmall: CGFloat  = 114   // small circular gauge (Battery temp)

    // MARK: - Dashboard Layout Components
    static let cardGlowRadius: CGFloat          = 120   // RadialGradient endRadius on SettingsDashboardCardBackground
    static let searchFieldWidth: CGFloat        = 180   // search field in SettingsContentHeader

    // MARK: - Menu Bar Popover Hero
    static let menuBarHeroGlowRadius: CGFloat   = 270   // RadialGradient endRadius on MenuBarView header

    // MARK: - Process Usage Row / Chart Hero
    static let processUsageBarWidth: CGFloat    = 180   // track width in SettingsProcessUsageRow
    static let heroChartHeight: CGFloat         = 108   // chart height in SettingsChartHeroCard
}

enum AppHTTPStatus {
    static let notFound: Int = 404
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
