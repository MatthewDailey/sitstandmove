import SwiftUI

/// The actor for the current phase: a white SF Symbol figure (the same symbols
/// used by the phase selectors and the menu bar) centered on a solid
/// phase-color tile, so it stays crisp and distinct from the panel behind it.
///
/// A bit of looping motion keeps it alive: breathing when seated, a gentle sway
/// when standing, and a walking bob when moving.
struct FigureView: View {
    let phase: Phase

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            TimelineView(.animation) { timeline in
                let m = motion(timeline.date.timeIntervalSinceReferenceDate)
                ZStack {
                    RoundedRectangle(cornerRadius: s * 0.17, style: .continuous)
                        .fill(phase.tint)
                    Image(systemName: phase.symbolName)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .frame(width: s * 0.56, height: s * 0.56)
                        .scaleEffect(CGSize(width: 1, height: m.scaleY), anchor: .bottom)
                        .rotationEffect(.degrees(m.rotation), anchor: .bottom)
                        .offset(y: m.offsetY * s / 120)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .accessibilityLabel("\(phase.title) figure")
    }

    /// Per-phase looping transform: (vertical scale, rotation°, vertical offset).
    private func motion(_ t: Double) -> (scaleY: Double, rotation: Double, offsetY: Double) {
        switch phase {
        case .sit:   return (1 + 0.04 * sin(t * 1.8), 0, 0)         // breathing
        case .stand: return (1, 2.0 * sin(t * 1.4), 0)             // sway
        case .move:  return (1, 1.5 * sin(t * 5.0), -abs(sin(t * 5.0)) * 5) // walking bob
        }
    }
}
