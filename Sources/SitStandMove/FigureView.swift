import SwiftUI

/// A solid restroom-pictogram "bathroom guy" performing the current action,
/// drawn white on a solid phase-color tile. The body is built from filled
/// *tapered* limbs (wide at the joint, narrow at the end) that overlap into one
/// smooth silhouette — broad rounded shoulders, a tapering trunk, legs split by
/// a thin notch — rather than uniform-width sticks.
///
/// Coordinates live in a 0...120 space (matching the source artwork) and are
/// scaled to the view at draw time. Looping motion: breathing + a foot tap when
/// seated, a gentle sway when standing, a march when moving.
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

    /// A tapered segment: half-width `wa` at point `a`, `wb` at point `b`.
    private struct Limb { var a: CGPoint; var wa: Double; var b: CGPoint; var wb: Double }
    private struct Fig { var head: CGPoint; var headR: Double; var limbs: [Limb]; var props: [Limb] }

    // MARK: - Rendering

    private func draw(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double) {
        let scale = min(size.width, size.height) / 120.0

        let m = 6 * scale
        let tile = CGRect(x: m, y: m, width: size.width - 2 * m, height: size.height - 2 * m)
        ctx.fill(Path(roundedRect: tile, cornerRadius: 26 * scale), with: .color(phase.tint))

        let fig = figure(t)
        for limb in fig.props + fig.limbs { fill(ctx, size, scale, limb) }

        let r = fig.headR * scale
        let c = point(fig.head, size)
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(.white))
    }

    /// Fill one tapered limb as two end-discs plus the connecting trapezoid.
    /// Overlapping white fills merge seamlessly into the unified silhouette.
    private func fill(_ ctx: GraphicsContext, _ size: CGSize, _ scale: Double, _ l: Limb) {
        let p0 = point(l.a, size), p1 = point(l.b, size)
        let r0 = l.wa * scale, r1 = l.wb * scale

        var discs = Path()
        discs.addEllipse(in: CGRect(x: p0.x - r0, y: p0.y - r0, width: 2 * r0, height: 2 * r0))
        discs.addEllipse(in: CGRect(x: p1.x - r1, y: p1.y - r1, width: 2 * r1, height: 2 * r1))
        ctx.fill(discs, with: .color(.white))

        let dx = p1.x - p0.x, dy = p1.y - p0.y
        let len = max(0.0001, (dx * dx + dy * dy).squareRoot())
        let nx = -dy / len, ny = dx / len
        var quad = Path()
        quad.move(to: CGPoint(x: p0.x + nx * r0, y: p0.y + ny * r0))
        quad.addLine(to: CGPoint(x: p1.x + nx * r1, y: p1.y + ny * r1))
        quad.addLine(to: CGPoint(x: p1.x - nx * r1, y: p1.y - ny * r1))
        quad.addLine(to: CGPoint(x: p0.x - nx * r0, y: p0.y - ny * r0))
        quad.closeSubpath()
        ctx.fill(quad, with: .color(.white))
    }

    // MARK: - Poses

    private func figure(_ t: Double) -> Fig {
        switch phase {
        case .sit:   return sitFig(t)
        case .stand: return standFig(t)
        case .move:  return moveFig(t)
        }
    }

    private func standFig(_ t: Double) -> Fig {
        let sx = sin(t * 1.4) * 1.3   // gentle upper-body sway
        return Fig(
            head: CGPoint(x: 60 + sx, y: 23), headR: 13,
            limbs: [
                L(60 + sx, 45, 20, 60, 73, 14),  // shoulders -> waist (broad, tapering)
                L(47 + sx, 49, 7.5, 44, 79, 6),  // left arm
                L(73 + sx, 49, 7.5, 76, 79, 6),  // right arm
                L(52, 73, 9, 52, 106, 7),        // left leg
                L(68, 73, 9, 68, 106, 7),        // right leg
            ],
            props: []
        )
    }

    private func sitFig(_ t: Double) -> Fig {
        let breathe = sin(t * 1.6) * 1.0          // slow breathing
        let tap = max(0, sin(t * 4.5)) * 3.0      // restless foot tap
        return Fig(
            head: CGPoint(x: 51, y: 27 + breathe), headR: 12.5,
            limbs: [
                L(54, 41 + breathe, 12, 57, 70, 12),       // torso (upright, side profile)
                L(55, 47 + breathe, 7, 71, 66, 5.5),       // arm resting forward
                L(57, 70, 11, 82, 73, 9),                  // thigh (horizontal)
                L(82, 73, 9, 82, 100 - tap, 7),            // shin (foot taps)
            ],
            props: [
                L(50, 82, 5, 86, 82, 5),      // stool seat slab
                L(80, 85, 3.5, 80, 108, 3.5), // front leg
                L(58, 85, 3.5, 58, 108, 3.5), // back leg
            ]
        )
    }

    private func moveFig(_ t: Double) -> Fig {
        // Side-profile walking stride: legs scissor fore/aft and arms counter-
        // swing, so it reads as walking even in a still frame.
        let s = sin(t * 4.5)
        let bob = -abs(s) * 1.6
        let hipY = 72 + bob * 0.6
        let kneeSpread = 9.0, footSpread = 17.0
        let frontLift = max(0, s) * 4, backLift = max(0, -s) * 4
        return Fig(
            head: CGPoint(x: 60, y: 23 + bob), headR: 13,
            limbs: [
                L(61, 45 + bob, 16, 59, hipY, 13),                                         // torso (leans forward)
                L(60, 49 + bob, 6.5, 60 - 13 * s, 71, 5),                                  // arm
                L(60, 49 + bob, 6.5, 60 + 13 * s, 71, 5),                                  // arm (opposite)
                L(59, hipY, 9, 59 + kneeSpread * s, 90 - frontLift, 8),                    // leg thigh
                L(59 + kneeSpread * s, 90 - frontLift, 8, 59 + footSpread * s, 106 - frontLift, 7), // leg shin
                L(59, hipY, 9, 59 - kneeSpread * s, 90 - backLift, 8),                     // leg thigh (opposite)
                L(59 - kneeSpread * s, 90 - backLift, 8, 59 - footSpread * s, 106 - backLift, 7),  // leg shin (opposite)
            ],
            props: []
        )
    }

    // MARK: - Helpers

    private func L(_ ax: Double, _ ay: Double, _ wa: Double,
                   _ bx: Double, _ by: Double, _ wb: Double) -> Limb {
        Limb(a: CGPoint(x: ax, y: ay), wa: wa, b: CGPoint(x: bx, y: by), wb: wb)
    }

    private func point(_ p: CGPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: p.x / 120 * size.width, y: p.y / 120 * size.height)
    }
}
