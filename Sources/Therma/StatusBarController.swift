import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSWindowDelegate {
    private let context: AppContext

    // Keep memory-related items together, then CPU-related items.
    private let memoryItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let networkItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let cpuItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let cpuUsageItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    private let memoryPopover = NSPopover()
    private let cpuPopover = NSPopover()
    private lazy var memoryHostingController = makeHostingController(for: .memory)
    private lazy var cpuHostingController = makeHostingController(for: .cpu)
    private var settingsWindow: NSWindow?
    private var observers: [NSObjectProtocol] = []
    private var lastStatusText: [MenuBarItem: String] = [:]

    init(context: AppContext) {
        self.context = context
        super.init()

        configurePopover(memoryPopover, mode: .memory)
        configurePopover(cpuPopover, mode: .cpu)
        configureButtons()
        registerObservers()
        refreshStatusItems()
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private var statusItems: [(item: MenuBarItem, statusItem: NSStatusItem)] {
        [
            (.memory, memoryItem),
            (.network, networkItem),
            (.cpu, cpuItem),
            (.cpuUsage, cpuUsageItem)
        ]
    }

    private func statusItem(for item: MenuBarItem) -> NSStatusItem {
        switch item {
        case .memory:
            return memoryItem
        case .network:
            return networkItem
        case .cpu:
            return cpuItem
        case .cpuUsage:
            return cpuUsageItem
        }
    }

    private func configurePopover(_ popover: NSPopover, mode: MonitorDisplayMode) {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = MenuBarPopoverMetrics.size(for: mode)
        let controller = mode == .memory ? memoryHostingController : cpuHostingController
        controller.view.wantsLayer = true
        _ = controller.view
        popover.contentViewController = controller
    }

    private func makeHostingController(for mode: MonitorDisplayMode) -> NSHostingController<MenuBarView> {
        NSHostingController(
            rootView: MenuBarView(
                ramMonitor: context.ramMonitor,
                cpuMonitor: context.cpuMonitor,
                systemMetricsMonitor: context.systemMetricsMonitor,
                preferences: context.preferences,
                displayModeOverride: mode,
                openSettingsAction: { [weak self] in self?.openSettings() }
            )
        )
    }

    private func configureButtons() {
        for (item, statusItem) in statusItems {
            guard let button = statusItem.button else { continue }
            button.target = self
            button.action = #selector(handleStatusItemClick(_:))
            button.sendAction(on: [.leftMouseUp])
            button.identifier = NSUserInterfaceItemIdentifier(item.rawValue)
        }
    }

    private func registerObservers() {
        observers.append(
            NotificationCenter.default.addObserver(
                forName: .thermaStatusBarDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshStatusItems()
                }
            }
        )
    }

    private func refreshStatusItems() {
        updateVisibility()
        for (item, _) in statusItems {
            updateButton(for: item)
        }
    }

    private func updateVisibility() {
        for (item, statusItem) in statusItems {
            statusItem.isVisible = context.preferences.isVisible(item)
        }
    }

    private func updateButton(for item: MenuBarItem) {
        let text = statusText(for: item)
        guard text != lastStatusText[item] else { return }
        lastStatusText[item] = text

        guard let button = statusItem(for: item).button else { return }

        // Network item: text-only, no icon (↓↑ already embedded in the value string)
        if item == .network {
            button.image = nil
        } else {
            button.image = symbolImage(
                systemName: item.icon,
                pointSize: context.preferences.iconSize(for: item)
            )
        }
        button.attributedTitle = attributedTitle(text, size: context.preferences.textSize(for: item))
        button.imagePosition = .imageLeading
        button.toolTip = tooltip(for: item)
    }

    private func statusText(for item: MenuBarItem) -> String {
        switch item {
        case .memory:
            return "\(context.ramMonitor.usagePercent)%"
        case .network:
            return context.systemMetricsMonitor.networkMenuBarDisplayValue
        case .cpu:
            if let celsius = context.cpuMonitor.currentCelsius {
                return context.preferences.formatCelsius(celsius)
            }
            return context.cpuMonitor.thermalLevel.shortLabel
        case .cpuUsage:
            return context.systemMetricsMonitor.cpuUsageDisplayValue
        }
    }

    private func tooltip(for item: MenuBarItem) -> String {
        switch item {
        case .memory:
            return "RAM Usage"
        case .network:
            return "Network Speed"
        case .cpu:
            return "CPU Temperature"
        case .cpuUsage:
            return "CPU Usage"
        }
    }

    private func popover(for item: MenuBarItem) -> NSPopover {
        item.group == .memory ? memoryPopover : cpuPopover
    }

    private func symbolImage(systemName: String, pointSize: Double) -> NSImage? {
        let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        return NSImage(systemSymbolName: systemName, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)
    }

    private func attributedTitle(_ value: String, size: Double) -> NSAttributedString {
        NSAttributedString(
            string: value,
            attributes: [
                .font: NSFont.systemFont(ofSize: size, weight: .regular),
                .foregroundColor: NSColor.white
            ]
        )
    }

    @objc
    private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard
            let identifier = sender.identifier?.rawValue,
            let item = MenuBarItem(rawValue: identifier)
        else { return }

        // cpuUsage and network are display-only items — no popover on click
        switch item {
        case .memory, .cpu:
            toggle(popover: popover(for: item), for: statusItem(for: item))
        case .network, .cpuUsage:
            break
        }
    }

    private func toggle(popover: NSPopover, for item: NSStatusItem) {
        guard let button = item.button else { return }

        if popover.isShown {
            popover.close()
        } else {
            if popover === memoryPopover {
                cpuPopover.close()
            } else {
                memoryPopover.close()
            }

            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func openSettings() {
        memoryPopover.performClose(nil)
        cpuPopover.performClose(nil)
        NSApp.activate(ignoringOtherApps: true)

        if settingsWindow == nil {
            let hostingController = NSHostingController(
                rootView: SettingsView(
                    preferences: context.preferences,
                    ramMonitor: context.ramMonitor,
                    cpuMonitor: context.cpuMonitor,
                    systemMetricsMonitor: context.systemMetricsMonitor,
                    updateManager: context.updateManager,
                    closeAction: { [weak self] in self?.settingsWindow?.close() }
                )
            )

            let window = NSWindow(
                contentRect: SettingsLayoutMetrics.windowFrameRect,
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Settings"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = false
            window.isReleasedWhenClosed = false
            window.setContentSize(SettingsLayoutMetrics.contentSize)
            window.minSize = window.frame.size
            window.center()
            window.contentViewController = hostingController
            window.delegate = self
            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard notification.object as AnyObject? === settingsWindow else { return }
        settingsWindow?.orderOut(nil)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController(context: AppContext.shared)
    }
}
