import SwiftUI
import AppKit

/// Off-screen rendering to PNG files. Used for quick visual checks and for
/// generating README artwork without launching the UI.
///
/// Usage: `SitStandMove --render [dir]`        — the three actor figures
///        `SitStandMove --render-panel [dir]`  — the popover panel, light + dark
enum RenderPreview {
    @MainActor
    static func run(arguments: [String]) {
        let dirURL = outputDir(arguments)
        for phase in Phase.allCases {
            let view = FigureView(phase: phase)
                .frame(width: 240, height: 240)
                .background(Color.white)
            write(view, scale: 2, to: dirURL.appendingPathComponent("\(phase.rawValue).png"))
        }
    }

    /// Render the popover panel in both appearances so light-mode contrast can
    /// be checked and a clean screenshot produced for the repo.
    @MainActor
    static func runPanels(arguments: [String]) {
        let dirURL = outputDir(arguments)
        let modes: [(name: String, scheme: ColorScheme, appearance: NSAppearance.Name)] = [
            ("light", .light, .aqua),
            ("dark",  .dark,  .darkAqua),
        ]
        for mode in modes {
            NSApp.appearance = NSAppearance(named: mode.appearance)
            let timer = TimerManager(settings: SettingsStore())
            let view = PopoverView(timer: timer, dismiss: {})
                .environment(\.colorScheme, mode.scheme)
            write(view, scale: 2, to: dirURL.appendingPathComponent("panel-\(mode.name).png"))
        }
    }

    // MARK: - Helpers

    private static func outputDir(_ arguments: [String]) -> URL {
        let dir = arguments.first(where: { !$0.hasPrefix("-") && $0 != arguments[0] })
            ?? NSTemporaryDirectory().appending("sitstandmove-preview")
        let url = URL(fileURLWithPath: dir, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @MainActor
    private static func write<V: View>(_ view: V, scale: CGFloat, to url: URL) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            FileHandle.standardError.write(Data("Failed to render \(url.lastPathComponent)\n".utf8))
            return
        }
        try? png.write(to: url)
        print("wrote \(url.path)")
    }
}
