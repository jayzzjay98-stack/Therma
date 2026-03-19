import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSWindowDelegate {
    private let context: AppContext

    private let memoryItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let cpuItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    private let memoryPopover = NSPopover()
    private let cpuPopover = NSPopover()
    private lazy var memoryHostingController = makeHostingController(for: .memory)
    private lazy var cpuHostingController = makeHostingController(for: .cpu)
    private var settingsWindow: NSWindow?

    private var refreshTimer: Timer?

    init(context: AppContext) {
        self.context = context
        super.init()

        configurePopover(memoryPopover, mode: .memory)
        configurePopover(cpuPopover, mode: .cpu)
        configureButtons()
        refreshStatusItems()
        startRefreshTimer()
    }

    deinit {
        refreshTimer?.invalidate()
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
                preferences: context.preferences,
                displayModeOverride: mode,
                openSettingsAction: { [weak self] in self?.openSettings() }
            )
        )
    }

    private func configureButtons() {
        if let button = memoryItem.button {
            button.target = self
            button.action = #selector(toggleMemoryPopover(_:))
            button.sendAction(on: [.leftMouseUp])
        }

        if let button = cpuItem.button {
            button.target = self
            button.action = #selector(toggleCPUPopover(_:))
            button.sendAction(on: [.leftMouseUp])
        }
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshStatusItems()
            }
        }

        if let refreshTimer {
            RunLoop.main.add(refreshTimer, forMode: .common)
        }
    }

    private func refreshStatusItems() {
        updateVisibility()
        updateMemoryButton()
        updateCPUButton()
    }

    private func updateVisibility() {
        memoryItem.isVisible = context.preferences.displayMode.showsMemory
        cpuItem.isVisible = context.preferences.displayMode.showsCPU
    }

    private func updateMemoryButton() {
        guard let button = memoryItem.button else { return }
        button.image = symbolImage(
            systemName: "cpu",
            pointSize: context.preferences.menuBarIconSize
        )
        button.attributedTitle = attributedTitle(
            "\(context.ramMonitor.usagePercent)%",
            size: context.preferences.menuBarTextSize
        )
        button.imagePosition = .imageLeading
        button.toolTip = "Therma"
    }

    private func updateCPUButton() {
        guard let button = cpuItem.button else { return }
        button.image = symbolImage(
            systemName: "thermometer.medium",
            pointSize: context.preferences.menuBarIconSize
        )
        let tempString: String
        if let celsius = context.cpuMonitor.currentCelsius {
            tempString = context.preferences.formatCelsius(celsius)
        } else {
            tempString = context.cpuMonitor.thermalLevel.shortLabel
        }
        button.attributedTitle = attributedTitle(
            tempString,
            size: context.preferences.menuBarTextSize
        )
        button.imagePosition = .imageLeading
        button.toolTip = "CPU Temperature"
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
    private func toggleMemoryPopover(_ sender: AnyObject?) {
        toggle(popover: memoryPopover, for: memoryItem)
    }

    @objc
    private func toggleCPUPopover(_ sender: AnyObject?) {
        toggle(popover: cpuPopover, for: cpuItem)
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
