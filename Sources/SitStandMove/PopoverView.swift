import SwiftUI

/// The little panel that pops out of the menu bar. Shows the current actor,
/// the time for the phase, and a single primary action.
struct PopoverView: View {
    @ObservedObject var timer: TimerManager
    let dismiss: () -> Void

    private var phase: Phase { timer.currentPhase }

    var body: some View {
        VStack(spacing: 14) {
            loopIndicator

            Text(headline)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            FigureView(phase: phase)
                .frame(width: 132, height: 132)

            Text(AppDelegate.format(timer.displaySeconds))
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)

            if !subhead.isEmpty {
                Text(subhead)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            controls
                .padding(.top, 2)
        }
        .padding(20)
        .frame(width: 260)
    }

    // MARK: - Pieces

    private var loopIndicator: some View {
        HStack(spacing: 12) {
            ForEach(Phase.loop, id: \.self) { p in
                let isCurrent = p == phase
                Button {
                    timer.selectStartPhase(p)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(isCurrent ? p.tint : Color.primary.opacity(0.06))
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .strokeBorder(Color.primary.opacity(isCurrent ? 0 : 0.10), lineWidth: 1)
                        Image(systemName: p.symbolName)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(isCurrent ? .white : Color.secondary)
                            .padding(11)
                    }
                    .frame(width: 48, height: 48)
                    // Whole tile is the hit target.
                    .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(timer.mode != .idle)
                .help(timer.mode == .idle ? "Start with \(p.title)" : p.title)
            }
        }
        .animation(.spring(response: 0.3), value: phase)
    }

    @ViewBuilder
    private var controls: some View {
        switch timer.mode {
        case .idle, .awaitingNext:
            primaryButton(timer.mode == .idle ? "Start" : "Start \(phase.title)") {
                timer.start()
                dismiss()
            }
        case .running:
            HStack(spacing: 10) {
                secondaryButton("Pause") { timer.pause() }
                secondaryButton("Skip") { timer.skip() }
            }
        case .paused:
            HStack(spacing: 10) {
                primaryButton("Resume") { timer.resume() }
                secondaryButton("Skip") { timer.skip() }
            }
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(phase.tint)
        .keyboardShortcut(.defaultAction)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    // MARK: - Text

    private var headline: String {
        switch timer.mode {
        case .awaitingNext: return phase.callToAction
        default:            return phase.title
        }
    }

    private var subhead: String {
        switch timer.mode {
        case .idle:         return ""
        case .running:      return "remaining"
        case .paused:       return "Paused"
        case .awaitingNext: return "Tap start to begin"
        }
    }
}
