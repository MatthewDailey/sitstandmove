import AppKit

// Hidden mode: render the actor figures to PNGs and exit. Handy for visual
// checks and README artwork without bringing up the menu bar UI.
if CommandLine.arguments.contains("--render") || CommandLine.arguments.contains("--render-panel") {
    let panels = CommandLine.arguments.contains("--render-panel")
    let renderApp = NSApplication.shared
    renderApp.setActivationPolicy(.prohibited)
    Task { @MainActor in
        if panels {
            RenderPreview.runPanels(arguments: CommandLine.arguments)
        } else {
            RenderPreview.run(arguments: CommandLine.arguments)
        }
        exit(0)
    }
    renderApp.run()
}

// Menu-bar-only app: no Dock icon, no main window. Everything lives in the
// status bar and is driven by AppDelegate.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
