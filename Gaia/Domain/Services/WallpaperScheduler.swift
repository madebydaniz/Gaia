import Foundation
import AppKit
import Combine

@MainActor
final class WallpaperScheduler {
    private let preferences: PreferencesService
    private let changeAction: () async -> Void
    private var timer: Timer?
    private var isChanging = false
    private var cancellables: Set<AnyCancellable> = []

    init(preferences: PreferencesService, changeAction: @escaping () async -> Void) {
        self.preferences = preferences
        self.changeAction = changeAction
    }

    func start() {
        observePreferencesIfNeeded()
        configureScheduler()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        NotificationCenter.default.removeObserver(self)
    }

    private func configureScheduler() {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)

        switch preferences.changeInterval {
        case .manual:
            return
        case .onLogin:
            Task { await changeIfNeeded(force: true) }
        case .onUnlock:
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleSessionActive),
                name: NSWorkspace.sessionDidBecomeActiveNotification,
                object: nil
            )
        case .hourly, .customHours, .everyThreeHours, .everySixHours, .daily, .weekly:
            guard let interval = resolvedInterval() else { return }
            timer = Timer.scheduledTimer(withTimeInterval: min(interval, 60 * 30), repeats: true) { [weak self] _ in
                Task { @MainActor in
                    await self?.changeIfNeeded()
                }
            }
            Task { await changeIfNeeded() }
        }
    }

    private func observePreferencesIfNeeded() {
        guard cancellables.isEmpty else { return }
        preferences.$changeInterval
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.configureScheduler()
                }
            }
            .store(in: &cancellables)
        preferences.$autoChangeHours
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in
                    if self?.preferences.changeInterval == .customHours {
                        self?.configureScheduler()
                    }
                }
            }
            .store(in: &cancellables)
    }

    @objc
    private func handleSessionActive() {
        Task { @MainActor in
            await changeIfNeeded(force: true)
        }
    }

    private func changeIfNeeded(force: Bool = false) async {
        guard !isChanging else { return }
        if !force {
            guard let interval = resolvedInterval() else { return }
            if let lastChangeDate = preferences.lastChangeDate,
               Date().timeIntervalSince(lastChangeDate) < interval {
                return
            }
        }
        isChanging = true
        await changeAction()
        isChanging = false
    }

    private func resolvedInterval() -> TimeInterval? {
        switch preferences.changeInterval {
        case .customHours:
            return TimeInterval(max(1, preferences.autoChangeHours) * 60 * 60)
        default:
            return preferences.changeInterval.timeInterval
        }
    }
}
