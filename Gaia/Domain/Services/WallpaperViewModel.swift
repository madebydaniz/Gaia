import AppKit
import Combine
import Foundation

@MainActor
final class WallpaperViewModel: ObservableObject {
    @Published var currentWallpaper: Wallpaper?
    @Published var wallpapers: [Wallpaper] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedSource: WallpaperSource
    @Published var statusText = "Ready"
    @Published var successMessage: String?
    @Published var updateInfo: AppUpdateInfo?
    @Published var isCheckingForUpdate = false

    private let service: WallpaperService
    private let preferences: PreferencesService
    private let updateService: AppUpdateChecking
    private let updateNotifier: UpdateNotifying
    private var currentIndex = 0
    private var mixedSourceHistory: [WallpaperSource] = []

    init(
        service: WallpaperService,
        preferences: PreferencesService,
        updateService: AppUpdateChecking,
        updateNotifier: UpdateNotifying
    ) {
        self.service = service
        self.preferences = preferences
        self.updateService = updateService
        self.updateNotifier = updateNotifier
        selectedSource = preferences.selectedSource
    }

    func loadInitialData() async {
        guard wallpapers.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        selectedSource = preferences.selectedSource
        let result = await service.loadWallpapers(source: selectedSource)
        wallpapers = result.wallpapers
        statusText = result.status
        errorMessage = result.wallpapers.isEmpty ? result.error?.localizedDescription : nil
        restoreCurrentWallpaper()
        await prefetchCurrentThumbnail()
    }

    func changeNow() async {
        guard !wallpapers.isEmpty else {
            await refresh()
            if wallpapers.isEmpty { return }
            return await changeNow()
        }
        let nextWallpaper = nextCandidate()
        await apply(nextWallpaper)
    }

    func next() async {
        guard !wallpapers.isEmpty else { return }
        currentIndex = (currentIndex + 1) % wallpapers.count
        currentWallpaper = wallpapers[currentIndex]
        errorMessage = nil
        await prefetchCurrentThumbnail()
    }

    func previous() async {
        guard !wallpapers.isEmpty else { return }
        currentIndex = (currentIndex - 1 + wallpapers.count) % wallpapers.count
        currentWallpaper = wallpapers[currentIndex]
        errorMessage = nil
        await prefetchCurrentThumbnail()
    }

    func toggleFavorite() async {
        guard let currentWallpaper else { return }
        do {
            let updated = try await service.toggleFavorite(currentWallpaper)
            replace(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func downloadOriginal() async {
        guard let currentWallpaper else { return }
        do {
            let updated = try await service.downloadOriginal(currentWallpaper)
            replace(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func revealInFinder() {
        guard let path = currentWallpaper?.localImagePath else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    func openSourcePage() {
        guard let url = currentWallpaper?.sourcePageURL else { return }
        NSWorkspace.shared.open(url)
    }

    func copyImageURL() {
        guard let url = currentWallpaper?.imageURL else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
    }

    func applyCurrentWallpaper() async {
        guard let currentWallpaper else { return }
        await apply(currentWallpaper)
    }

    func clearThumbnails() async {
        do {
            try await service.clearThumbnails()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearDownloadedImages() async {
        do {
            try await service.clearDownloadedImages()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func checkForUpdatesIfNeeded(onLaunch: Bool) async {
        if onLaunch, !preferences.checkOnLaunch { return }
        if onLaunch,
           let lastCheck = preferences.lastUpdateCheckDate,
           Date().timeIntervalSince(lastCheck) < 24 * 60 * 60 {
            return
        }
        await checkForUpdates()
    }

    func checkForUpdates() async {
        isCheckingForUpdate = true
        defer { isCheckingForUpdate = false }
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        do {
            let info = try await updateService.checkForUpdates(currentVersion: currentVersion)
            updateInfo = info
            preferences.lastUpdateCheckDate = Date()
            if info.isUpdateAvailable {
                await updateNotifier.notifyIfNeeded(
                    latestVersion: info.latestVersion,
                    releaseURL: info.releaseURL,
                    preferences: preferences
                )
            }
        } catch {
            // Keep UX quiet for update checks; no blocking error for wallpaper flow.
        }
    }

    func openUpdateDownloadPage() {
        guard let url = updateInfo?.releaseURL else { return }
        NSWorkspace.shared.open(url)
    }

    private func apply(_ wallpaper: Wallpaper) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let updated = try await service.setWallpaper(wallpaper)
            replace(updated)
            errorMessage = nil
            showSuccessMessage(for: updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func showSuccessMessage(for wallpaper: Wallpaper) {
        let title = wallpaper.title?.isEmpty == false ? wallpaper.title! : (wallpaper.locationName ?? wallpaper.source.displayName)
        successMessage = "Applied: \(title)"
        let message = successMessage
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if successMessage == message {
                successMessage = nil
            }
        }
    }

    private func nextCandidate() -> Wallpaper {
        switch preferences.shuffleMode {
        case .random:
            return wallpapers.randomElement() ?? wallpapers[currentIndex]
        case .mixedSources:
            return mixedBalancedCandidate()
        default:
            if selectedSource == .mixed {
                return mixedBalancedCandidate()
            }
            currentIndex = (currentIndex + 1) % wallpapers.count
            return wallpapers[currentIndex]
        }
    }

    private func mixedBalancedCandidate() -> Wallpaper {
        let grouped = Dictionary(grouping: wallpapers, by: \.source)
        guard !grouped.isEmpty else {
            return wallpapers[currentIndex]
        }

        let recentWindow = Array(mixedSourceHistory.suffix(8))
        let usage = Dictionary(recentWindow.map { ($0, 1) }, uniquingKeysWith: +)
        let minUsage = grouped.keys.map { usage[$0, default: 0] }.min() ?? 0

        let leastUsed = grouped.keys.filter { usage[$0, default: 0] == minUsage }
        let currentSource = currentWallpaper?.source
        let sourcePool = leastUsed.filter { $0 != currentSource }.isEmpty ? leastUsed : leastUsed.filter { $0 != currentSource }
        let pickedSource = sourcePool.randomElement() ?? leastUsed.randomElement() ?? wallpapers[currentIndex].source

        let sourceWallpapers = grouped[pickedSource] ?? wallpapers
        let poolWithoutCurrent = sourceWallpapers.filter { $0.id != currentWallpaper?.id }
        let chosen = (poolWithoutCurrent.isEmpty ? sourceWallpapers : poolWithoutCurrent).randomElement() ?? wallpapers[currentIndex]

        mixedSourceHistory.append(chosen.source)
        if mixedSourceHistory.count > 20 {
            mixedSourceHistory.removeFirst(mixedSourceHistory.count - 20)
        }
        return chosen
    }

    private func restoreCurrentWallpaper() {
        if let id = preferences.lastSelectedWallpaperId,
           let index = wallpapers.firstIndex(where: { $0.id == id }) {
            currentIndex = index
        } else {
            currentIndex = 0
        }
        currentWallpaper = wallpapers.indices.contains(currentIndex) ? wallpapers[currentIndex] : nil
    }

    private func replace(_ wallpaper: Wallpaper) {
        if let index = wallpapers.firstIndex(where: { $0.id == wallpaper.id }) {
            wallpapers[index] = wallpaper
            currentIndex = index
        }
        currentWallpaper = wallpaper
    }

    private func prefetchCurrentThumbnail() async {
        guard let currentWallpaper, currentWallpaper.localThumbnailPath == nil else { return }
        if let updated = try? await service.downloadThumbnail(currentWallpaper) {
            replace(updated)
        }
    }
}
