import Foundation
import Combine

/// Persists the only thing the user can configure: how long each phase lasts.
final class SettingsStore: ObservableObject {
    private let defaults: UserDefaults

    @Published var sitMinutes: Double {
        didSet { defaults.set(sitMinutes, forKey: Key.sit) }
    }
    @Published var standMinutes: Double {
        didSet { defaults.set(standMinutes, forKey: Key.stand) }
    }
    @Published var moveMinutes: Double {
        didSet { defaults.set(moveMinutes, forKey: Key.move) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.sitMinutes = SettingsStore.read(Key.sit, defaults: defaults, fallback: Phase.sit.defaultMinutes)
        self.standMinutes = SettingsStore.read(Key.stand, defaults: defaults, fallback: Phase.stand.defaultMinutes)
        self.moveMinutes = SettingsStore.read(Key.move, defaults: defaults, fallback: Phase.move.defaultMinutes)
    }

    /// Minutes configured for a given phase.
    func minutes(for phase: Phase) -> Double {
        switch phase {
        case .sit:   return sitMinutes
        case .stand: return standMinutes
        case .move:  return moveMinutes
        }
    }

    /// Duration in seconds for a given phase.
    func duration(for phase: Phase) -> TimeInterval {
        max(1, minutes(for: phase) * 60)
    }

    private static func read(_ key: String, defaults: UserDefaults, fallback: Double) -> Double {
        if defaults.object(forKey: key) != nil {
            return defaults.double(forKey: key)
        }
        return fallback
    }

    private enum Key {
        static let sit = "sitMinutes"
        static let stand = "standMinutes"
        static let move = "moveMinutes"
    }
}
