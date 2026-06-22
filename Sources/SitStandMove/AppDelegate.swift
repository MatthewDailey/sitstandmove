import AppKit
import SwiftUI
import Combine
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let settings = SettingsStore()
    private lazy var timer = TimerManager(settings: settings)

    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var settingsWindow: NSWindow?
    private var cancellable: AnyCancellable?
    private var iconAllowance: CGFloat = 18  // widest phase icon, measured at launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar-only: keep the app out of the Dock and the app switcher.
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // Remember where the user Cmd-drags the icon, across relaunches.
        statusItem.autosaveName = "SitStandMove"
        if let button = statusItem.button {
            button.action = #selector(statusButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            // Monospaced digits so the ticking countdown keeps a fixed width and
            // doesn't shove the icon back and forth.
            let size = button.font?.pointSize ?? NSFont.systemFontSize
            button.font = NSFont.monospacedDigitSystemFont(ofSize: size, weight: .regular)
        }

        iconAllowance = Phase.loop.compactMap {
            NSImage(systemSymbolName: $0.symbolName, accessibilityDescription: nil)?.size.width
        }.max() ?? 18

        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(timer: timer, dismiss: { [weak self] in self?.closePopover() })
        )

        // When a phase ends, chime and pop the panel open for confirmation.
        timer.onPrompt = { [weak self] in
            self?.playChime()
            self?.openPopover()
        }

        // Refresh the menu bar label whenever the timer state changes.
        cancellable = timer.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.updateStatusButton() }

        updateStatusButton()
    }

    // MARK: - Status bar

    private func updateStatusButton() {
        guard let button = statusItem.button else { return }
        let phase = timer.currentPhase
        let image = NSImage(systemSymbolName: phase.symbolName,
                            accessibilityDescription: phase.title)
        image?.isTemplate = true
        button.image = image
        button.imagePosition = .imageLeading

        switch timer.mode {
        case .running, .paused:
            button.title = " " + Self.format(timer.remaining)
        case .idle, .awaitingNext:
            button.title = ""  // just the icon when no countdown is running
        }

        // Two fixed widths so the item never shifts within a mode: a narrow,
        // icon-only width when not timing, and a wider icon+countdown width while
        // timing. (The width only changes once, when a timer starts or stops.)
        statusItem.length = fixedStatusLength()
    }

    private func fixedStatusLength() -> CGFloat {
        switch timer.mode {
        case .running, .paused:
            guard let font = statusItem.button?.font else { return 72 }
            let longestMinutes = max(settings.sitMinutes, settings.standMinutes, settings.moveMinutes)
            let widest = " " + Self.format(longestMinutes * 60)
            let textWidth = (widest as NSString).size(withAttributes: [.font: font]).width
            return ceil(textWidth) + 30  // icon + image/title spacing + button padding
        case .idle, .awaitingNext:
            return ceil(iconAllowance) + 18  // widest icon + button padding
        }
    }

    static func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    // MARK: - Click handling

    @objc private func statusButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true
        if isRightClick {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
            .target = self
        menu.addItem(withTitle: "Reset Loop", action: #selector(resetLoop), keyEquivalent: "")
            .target = self

        let launch = NSMenuItem(title: "Launch at Login",
                                action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launch.target = self
        launch.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        menu.addItem(launch)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit SitStandMove", action: #selector(quit), keyEquivalent: "q")
            .target = self

        // Attaching the menu and clicking shows it anchored under the item;
        // detaching afterwards keeps left-click bound to our action.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    // MARK: - Popover

    private func togglePopover() {
        if popover.isShown { closePopover() } else { openPopover() }
    }

    private func openPopover() {
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func closePopover() {
        popover.performClose(nil)
    }

    // MARK: - Menu actions

    @objc private func openSettings() {
        if settingsWindow == nil {
            let hosting = NSHostingController(rootView: SettingsView(settings: settings))
            let window = NSWindow(contentViewController: hosting)
            window.title = "SitStandMove"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func resetLoop() {
        timer.reset()
        updateStatusButton()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("SitStandMove: launch-at-login toggle failed: \(error.localizedDescription)")
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Sound

    private func playChime() {
        NSSound(named: "Glass")?.play()
    }
}
