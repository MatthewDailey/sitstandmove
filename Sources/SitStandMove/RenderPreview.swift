import SwiftUI
import AppKit

/// Off-screen rendering of the actor figures to PNG files. Used for quick
/// visual checks and for generating README artwork without launching the UI.
///
/// Usage: `SitStandMove --render [output-directory]`
enum RenderPreview {
    @MainActor
    static func run(arguments: [String]) {
        let dir = arguments.first(where: { !$0.hasPrefix("-") && $0 != arguments[0] })
            ?? NSTemporaryDirectory().appending("sitstandmove-preview")
        let dirURL = URL(fileURLWithPath: dir, isDirectory: true)
        try? FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)

        for phase in Phase.allCases {
            let view = FigureView(phase: phase)
                .frame(width: 240, height: 240)
                .background(Color.white)

            let renderer = ImageRenderer(content: view)
            renderer.scale = 2

            guard let image = renderer.nsImage,
                  let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let png = bitmap.representation(using: .png, properties: [:]) else {
                FileHandle.standardError.write(Data("Failed to render \(phase.title)\n".utf8))
                continue
            }
            let outURL = dirURL.appendingPathComponent("\(phase.rawValue).png")
            try? png.write(to: outURL)
            print("wrote \(outURL.path)")
        }
    }
}
