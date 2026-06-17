import SwiftUI

/// The only configuration screen: how many minutes each phase lasts.
struct SettingsView: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Loop Durations")
                .font(.headline)

            durationRow(phase: .sit, value: $settings.sitMinutes)
            durationRow(phase: .stand, value: $settings.standMinutes)
            durationRow(phase: .move, value: $settings.moveMinutes)

            Divider()

            Text("Right-click the menu bar icon any time to reopen these settings.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 340)
    }

    private func durationRow(phase: Phase, value: Binding<Double>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: phase.symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(phase.tint)
                .frame(width: 24)

            Text(phase.title)
                .frame(width: 56, alignment: .leading)

            Stepper(value: value, in: 1...120, step: 1) {
                Text("\(Int(value.wrappedValue)) min")
                    .monospacedDigit()
            }
        }
    }
}
