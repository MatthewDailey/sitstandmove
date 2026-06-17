import SwiftUI

/// A little restroom-sign style person that performs the current action with a
/// bit of looping motion: sitting (gentle breathing), standing (soft sway),
/// or moving (marching in place).
struct FigureView: View {
    let phase: Phase

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                drawScene(in: context, size: size, t: t)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(phase.tint.opacity(0.12))
        )
        .accessibilityLabel("\(phase.title) figure")
    }

    // MARK: - Skeleton, posed per phase

    /// Joints in a normalized 0...1 space (y points down), built fresh each
    /// frame so the limbs can be animated.
    private struct Pose {
        var head: CGPoint
        var torsoTop: CGPoint
        var torsoBottom: CGPoint
        var leftArm: [CGPoint]   // shoulder, elbow, hand
        var rightArm: [CGPoint]
        var leftLeg: [CGPoint]   // hip, knee, foot
        var rightLeg: [CGPoint]
        var showChair: Bool
    }

    private func pose(t: Double) -> Pose {
        switch phase {
        case .stand: return standPose(t: t)
        case .move:  return movePose(t: t)
        case .sit:   return sitPose(t: t)
        }
    }

    private func standPose(t: Double) -> Pose {
        let sway = 0.012 * sin(t * 1.5)
        let bob = 0.004 * sin(t * 1.5)
        let left = Pose(
            head: p(0.5 + sway, 0.17 + bob),
            torsoTop: p(0.5 + sway * 0.8, 0.30 + bob),
            torsoBottom: p(0.5, 0.56),
            leftArm: [p(0.5 + sway - 0.10, 0.33 + bob), p(0.5 + sway - 0.13, 0.45), p(0.5 + sway - 0.14, 0.57)],
            rightArm: [p(0.5 + sway + 0.10, 0.33 + bob), p(0.5 + sway + 0.13, 0.45), p(0.5 + sway + 0.14, 0.57)],
            leftLeg: [p(0.5 - 0.06, 0.56), p(0.5 - 0.055, 0.74), p(0.5 - 0.06, 0.92)],
            rightLeg: [p(0.5 + 0.06, 0.56), p(0.5 + 0.055, 0.74), p(0.5 + 0.06, 0.92)],
            showChair: false
        )
        return left
    }

    private func movePose(t: Double) -> Pose {
        let s = sin(t * 5.5)
        let bob = -abs(s) * 0.012
        let rk = max(0, s) * 0.13   // right knee lift
        let lk = max(0, -s) * 0.13  // left knee lift
        return Pose(
            head: p(0.5, 0.17 + bob),
            torsoTop: p(0.5, 0.30 + bob),
            torsoBottom: p(0.5, 0.56 + bob * 0.5),
            // Front-view arm pump: hands rise and fall in opposition.
            leftArm: [p(0.5 - 0.10, 0.33 + bob), p(0.5 - 0.13, 0.44 - 0.05 * s), p(0.5 - 0.15, 0.55 - 0.12 * s)],
            rightArm: [p(0.5 + 0.10, 0.33 + bob), p(0.5 + 0.13, 0.44 + 0.05 * s), p(0.5 + 0.15, 0.55 + 0.12 * s)],
            leftLeg: [p(0.5 - 0.06, 0.56 + bob * 0.5), p(0.5 - 0.06, 0.74 - lk), p(0.5 - 0.07 + lk * 0.3, 0.92 - lk * 1.7)],
            rightLeg: [p(0.5 + 0.06, 0.56 + bob * 0.5), p(0.5 + 0.06, 0.74 - rk), p(0.5 + 0.07 - rk * 0.3, 0.92 - rk * 1.7)],
            showChair: false
        )
    }

    private func sitPose(t: Double) -> Pose {
        let breathe = 0.005 * sin(t * 1.4)
        return Pose(
            head: p(0.5, 0.22 + breathe),
            torsoTop: p(0.5, 0.35 + breathe),
            torsoBottom: p(0.5, 0.60),
            leftArm: [p(0.5 - 0.10, 0.37 + breathe), p(0.5 - 0.15, 0.50), p(0.5 - 0.16, 0.63)],
            rightArm: [p(0.5 + 0.10, 0.37 + breathe), p(0.5 + 0.15, 0.50), p(0.5 + 0.16, 0.63)],
            // Thighs angle out to the knees, shins drop straight down.
            leftLeg: [p(0.5 - 0.06, 0.60), p(0.5 - 0.17, 0.65), p(0.5 - 0.17, 0.88)],
            rightLeg: [p(0.5 + 0.06, 0.60), p(0.5 + 0.17, 0.65), p(0.5 + 0.17, 0.88)],
            showChair: true
        )
    }

    // MARK: - Rendering

    private func drawScene(in context: GraphicsContext, size: CGSize, t: Double) {
        let pose = pose(t: t)
        let unit = min(size.width, size.height)
        let limb = StrokeStyle(lineWidth: unit * 0.075, lineCap: .round, lineJoin: .round)
        let color = GraphicsContext.Shading.color(phase.tint)

        if pose.showChair {
            drawChair(in: context, size: size)
        }

        // Limbs and torso.
        context.stroke(polyline(pose.leftLeg, size), with: color, style: limb)
        context.stroke(polyline(pose.rightLeg, size), with: color, style: limb)
        context.stroke(polyline([pose.torsoTop, pose.torsoBottom], size), with: color, style: limb)
        context.stroke(polyline(pose.leftArm, size), with: color, style: limb)
        context.stroke(polyline(pose.rightArm, size), with: color, style: limb)

        // Head.
        let r = unit * 0.105
        let c = scale(pose.head, size)
        let headRect = CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
        context.fill(Path(ellipseIn: headRect), with: color)
    }

    private func drawChair(in context: GraphicsContext, size: CGSize) {
        let shade = GraphicsContext.Shading.color(.secondary.opacity(0.35))
        let seat = CGRect(
            x: 0.28 * size.width, y: 0.65 * size.height,
            width: 0.44 * size.width, height: 0.055 * size.height
        )
        context.fill(Path(roundedRect: seat, cornerRadius: 0.02 * size.width), with: shade)
        for x in [0.33, 0.67] {
            let leg = CGRect(
                x: x * size.width, y: 0.70 * size.height,
                width: 0.035 * size.width, height: 0.20 * size.height
            )
            context.fill(Path(roundedRect: leg, cornerRadius: 0.012 * size.width), with: shade)
        }
    }

    // MARK: - Helpers

    private func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    private func scale(_ pt: CGPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: pt.x * size.width, y: pt.y * size.height)
    }

    private func polyline(_ points: [CGPoint], _ size: CGSize) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: scale(first, size))
        for pt in points.dropFirst() { path.addLine(to: scale(pt, size)) }
        return path
    }
}
