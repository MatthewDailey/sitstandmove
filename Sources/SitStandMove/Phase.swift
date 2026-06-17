import SwiftUI

/// One step in the sit / stand / move loop.
enum Phase: String, CaseIterable, Codable {
    case sit
    case stand
    case move

    /// Display title, e.g. "Sit".
    var title: String { rawValue.capitalized }

    /// Imperative shown when the panel pops open, e.g. "Time to stand".
    var callToAction: String { "Time to \(rawValue)" }

    /// SF Symbol used in the menu bar and the loop indicator.
    var symbolName: String {
        switch self {
        case .sit:   return "figure.seated.side"
        case .stand: return "figure.stand"
        case .move:  return "figure.walk"
        }
    }

    /// Accent color for the phase.
    var tint: Color {
        switch self {
        case .sit:   return Color(red: 0.30, green: 0.55, blue: 0.95) // blue
        case .stand: return Color(red: 0.25, green: 0.70, blue: 0.45) // green
        case .move:  return Color(red: 0.95, green: 0.55, blue: 0.20) // orange
        }
    }

    /// The fixed order the loop cycles through.
    static let loop: [Phase] = [.sit, .stand, .move]

    /// Default duration in minutes, used the first time the app runs.
    ///
    /// These follow the widely-cited **20-8-2 rule** from office-ergonomics
    /// research (Cornell University Ergonomics / Prof. Alan Hedge): for each
    /// half hour, sit ~20 min, stand ~8 min, then move ~2 min — the ratio found
    /// to best break up prolonged sitting without tiring you out.
    var defaultMinutes: Double {
        switch self {
        case .sit:   return 20
        case .stand: return 8
        case .move:  return 2
        }
    }
}
