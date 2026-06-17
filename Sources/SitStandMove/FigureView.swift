import SwiftUI

/// A little restroom-sign style person performing the current action, drawn as
/// a crisp solid-white silhouette on a solid phase-color tile (the "Sign"
/// design direction) with a bit of looping motion: breathing while sitting,
/// swaying while standing, marching while moving.
///
/// All coordinates below live in a 0...120 space matching the source artwork,
/// and are scaled to the view at draw time.
struct FigureView: View {
    let phase: Phase

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                draw(context, size, timeline.date.timeIntervalSinceReferenceDate)
            }
        }
        .accessibilityLabel("\(phase.title) figure")
    }

    private struct Limb { var points: [CGPoint]; var width: Double }
    private struct Figure { var head: CGPoint; var headRadius: Double; var limbs: [Limb]; var props: [Limb] }

    // MARK: - Rendering

    private func draw(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double) {
        let unit = min(size.width, size.height)
        let scale = unit / 120.0

        // Solid phase-color tile: the high-contrast backdrop that makes the
        // white figure pop and stay distinct from the panel behind it.
        let margin = 6.0 * scale
        let tileRect = CGRect(x: margin, y: margin,
                              width: size.width - 2 * margin,
                              height: size.height - 2 * margin)
        ctx.fill(Path(roundedRect: tileRect, cornerRadius: 26 * scale), with: .color(phase.tint))

        let figure = figure(t: t)
        let white = GraphicsContext.Shading.color(.white)

        for limb in figure.props + figure.limbs {
            ctx.stroke(path(limb.points, size), with: white,
                       style: StrokeStyle(lineWidth: limb.width * scale, lineCap: .round, lineJoin: .round))
        }

        let r = figure.headRadius * scale
        let c = point(figure.head, size)
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: white)
    }

    // MARK: - Poses

    private func figure(t: Double) -> Figure {
        switch phase {
        case .sit:   return sit(t)
        case .stand: return stand(t)
        case .move:  return move(t)
        }
    }

    private func sit(_ t: Double) -> Figure {
        let b = sin(t * 1.6) * 1.3   // gentle breathing of the upper body
        return Figure(
            head: CGPoint(x: 55, y: 30 + b),
            headRadius: 12,
            limbs: [
                Limb(points: [CGPoint(x: 55, y: 46 + b), CGPoint(x: 57, y: 67)], width: 17),  // torso
                Limb(points: [CGPoint(x: 55, y: 67), CGPoint(x: 80, y: 67)], width: 16),       // thigh
                Limb(points: [CGPoint(x: 80, y: 67), CGPoint(x: 80, y: 88)], width: 13),       // shin
                Limb(points: [CGPoint(x: 58, y: 52 + b * 0.7), CGPoint(x: 41, y: 62 + b * 0.3)], width: 11), // arm
            ],
            props: [
                Limb(points: [CGPoint(x: 42, y: 90), CGPoint(x: 82, y: 90)], width: 9),  // seat
                Limb(points: [CGPoint(x: 47, y: 92), CGPoint(x: 47, y: 109)], width: 8), // chair leg
                Limb(points: [CGPoint(x: 77, y: 92), CGPoint(x: 77, y: 109)], width: 8), // chair leg
            ]
        )
    }

    private func stand(_ t: Double) -> Figure {
        let sx = sin(t * 1.5) * 1.5   // gentle sway of the upper body
        return Figure(
            head: CGPoint(x: 60 + sx, y: 29),
            headRadius: 12,
            limbs: [
                Limb(points: [CGPoint(x: 60 + sx, y: 45), CGPoint(x: 60, y: 74)], width: 18), // torso
                Limb(points: [CGPoint(x: 54, y: 76), CGPoint(x: 54, y: 102)], width: 13),      // leg
                Limb(points: [CGPoint(x: 66, y: 76), CGPoint(x: 66, y: 102)], width: 13),      // leg
                Limb(points: [CGPoint(x: 50 + sx, y: 50), CGPoint(x: 48, y: 74)], width: 11),  // arm
                Limb(points: [CGPoint(x: 70 + sx, y: 50), CGPoint(x: 72, y: 74)], width: 11),  // arm
            ],
            props: []
        )
    }

    private func move(_ t: Double) -> Figure {
        let s = sin(t * 5.0)
        let bob = -abs(s) * 1.6        // body rises slightly with each step
        let lift = 14.0
        let lk = max(0, -s) * lift     // left knee/foot lift
        let rk = max(0,  s) * lift     // right knee/foot lift
        let hipY = 73 + bob * 0.6
        return Figure(
            head: CGPoint(x: 60, y: 29 + bob),
            headRadius: 12,
            limbs: [
                Limb(points: [CGPoint(x: 60, y: 45 + bob), CGPoint(x: 59, y: 71 + bob * 0.6)], width: 18), // torso
                Limb(points: [CGPoint(x: 54, y: hipY), CGPoint(x: 54, y: 90 - lk), CGPoint(x: 54, y: 104 - lk * 1.5)], width: 13),
                Limb(points: [CGPoint(x: 66, y: hipY), CGPoint(x: 66, y: 90 - rk), CGPoint(x: 66, y: 104 - rk * 1.5)], width: 13),
                Limb(points: [CGPoint(x: 51, y: 50 + bob), CGPoint(x: 45, y: 64 - 8 * s)], width: 11), // arm
                Limb(points: [CGPoint(x: 69, y: 50 + bob), CGPoint(x: 75, y: 64 + 8 * s)], width: 11), // arm
            ],
            props: []
        )
    }

    // MARK: - Helpers

    private func point(_ p: CGPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: p.x / 120 * size.width, y: p.y / 120 * size.height)
    }

    private func path(_ points: [CGPoint], _ size: CGSize) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: point(first, size))
        for p in points.dropFirst() { path.addLine(to: point(p, size)) }
        return path
    }
}
