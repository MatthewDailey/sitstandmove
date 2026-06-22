import Foundation
import Combine

/// Drives the sit / stand / move loop and the countdown for the active phase.
///
/// Everything here runs on the main run loop (the ticking `Timer` is scheduled
/// on it and all callers are UI), so no extra synchronization is needed.
final class TimerManager: ObservableObject {

    enum Mode {
        case idle          // nothing started yet
        case running       // counting down the current phase
        case paused        // countdown held
        case awaitingNext  // a phase just ended; waiting for the user to start the next one
    }

    @Published private(set) var mode: Mode = .idle
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var remaining: TimeInterval = 0

    /// Called when a phase ends and the panel should pop open for confirmation.
    var onPrompt: (() -> Void)?

    let settings: SettingsStore
    private let order = Phase.loop
    private var ticker: Timer?
    private var deadline: Date?
    private var settingsCancellable: AnyCancellable?

    init(settings: SettingsStore) {
        self.settings = settings
        self.remaining = settings.duration(for: order[0])

        // Reflect duration changes live: republish so the panel/menu bar update,
        // and resync the displayed time whenever we're not mid-countdown.
        settingsCancellable = settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.settingsChanged() }
    }

    private func settingsChanged() {
        if mode == .idle || mode == .awaitingNext {
            remaining = settings.duration(for: currentPhase)
        }
        objectWillChange.send()
    }

    // MARK: - Derived state

    var currentPhase: Phase { order[currentIndex] }

    /// Pick which phase is active. Allowed any time the loop isn't actively
    /// counting down (idle, paused, or awaiting the next phase). Switches to the
    /// chosen phase, resets it to its full duration, and parks it ready to start.
    func selectStartPhase(_ phase: Phase) {
        guard mode != .running, let index = order.firstIndex(of: phase) else { return }
        stopTicker()
        deadline = nil
        currentIndex = index
        remaining = settings.duration(for: currentPhase)
        mode = .idle
    }

    /// Seconds to display: live countdown while running/paused, otherwise the
    /// full configured duration for the current phase.
    var displaySeconds: TimeInterval {
        switch mode {
        case .running, .paused: return remaining
        case .idle, .awaitingNext: return settings.duration(for: currentPhase)
        }
    }

    // MARK: - Controls

    /// Begin (or resume from awaiting) counting down the current phase.
    func start() {
        if remaining <= 0 || mode == .idle || mode == .awaitingNext {
            remaining = settings.duration(for: currentPhase)
        }
        deadline = Date().addingTimeInterval(remaining)
        mode = .running
        startTicker()
    }

    func pause() {
        guard mode == .running else { return }
        updateRemaining()
        stopTicker()
        deadline = nil
        mode = .paused
    }

    func resume() {
        guard mode == .paused else { return }
        deadline = Date().addingTimeInterval(remaining)
        mode = .running
        startTicker()
    }

    /// Skip straight to the next phase and start counting it down.
    func skip() {
        advanceIndex()
        start()
    }

    /// Stop the loop and return to the very beginning.
    func reset() {
        stopTicker()
        deadline = nil
        currentIndex = 0
        remaining = settings.duration(for: currentPhase)
        mode = .idle
    }

    // MARK: - Ticking

    private func startTicker() {
        stopTicker()
        let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // .common keeps it firing while menus / popovers are tracking events.
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func tick() {
        guard mode == .running else { return }
        updateRemaining()
        if remaining <= 0 {
            phaseEnded()
        }
    }

    private func updateRemaining() {
        guard let deadline else { return }
        remaining = max(0, deadline.timeIntervalSinceNow)
    }

    private func phaseEnded() {
        stopTicker()
        deadline = nil
        advanceIndex()
        remaining = settings.duration(for: currentPhase)
        mode = .awaitingNext
        onPrompt?()
    }

    private func advanceIndex() {
        currentIndex = (currentIndex + 1) % order.count
    }
}
