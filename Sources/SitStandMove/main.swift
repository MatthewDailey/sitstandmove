import AppKit

// Menu-bar-only app: no Dock icon, no main window. Everything lives in the
// status bar and is driven by AppDelegate.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
