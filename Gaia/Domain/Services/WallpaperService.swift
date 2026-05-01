import Foundation

enum WallpaperServiceError: Error, LocalizedError {
    case repositoryUnavailable(WallpaperSource)
    case noWallpapersAvailable
    case imageUnavailable

    var errorDescription: String? {
        switch self {
        case .repositoryUnavailable(let source):
            "\(source.displayName) \(String(localized: "error.repository_unavailable_suffix"))"
        case .noWallpapersAvailable:
            String(localized: "error.no_wallpapers")
        case .imageUnavailable:
            String(localized: "error.image_unavailable")
        }
    }
}

final class WallpaperService {
    private let repositories: [WallpaperSource: WallpaperRepository]
    private let localRepository: WallpaperLocalRepository
    private let downloader: WallpaperImageDownloader
    private let wallpaperSetter: WallpaperSetter
    private let preferences: PreferencesService
    private let fallbackProvider: WallpaperFallbackProvider?

    init(
        repositories: [WallpaperSource: WallpaperRepository],
        localRepository: WallpaperLocalRepository,
        downloader: WallpaperImageDownloader,
        wallpaperSetter: WallpaperSetter,
        preferences: PreferencesService,
        fallbackProvider: WallpaperFallbackProvider? = nil
    ) {
        self.repositories = repositories
        self.localRepository = localRepository
        self.downloader = downloader
        self.wallpaperSetter = wallpaperSetter
        self.preferences = preferences
        self.fallbackProvider = fallbackProvider
    }

    func loadWallpapers(source: WallpaperSource) async -> (wallpapers: [Wallpaper], status: String, error: Error?) {
        if source == .favorites {
            let all = (try? await localRepository.loadMetadata(source: nil)) ?? []
            let favorites = sort(all.filter(\.isFavorite))
            return (favorites, "status.favorites", nil)
        }

        do {
            let remote = try await fetchRemote(source: source)
            let merged = try await mergeWithLocalState(remote, source: source)
            try await localRepository.saveMetadata(merged, source: source)
            preferences.lastRefreshDate = Date()
            return (sort(merged), "status.updated_today", nil)
        } catch {
            let limited = isRateLimited(error)
            if let cached = try? await localRepository.loadMetadata(source: source), !cached.isEmpty {
                return (sort(cached), limited ? "status.rate_limited_cache" : "status.offline_cache", nil)
            }
            if let fallback = try? await fallbackProvider?.loadFallback(source: source), !fallback.isEmpty {
                return (sort(fallback), limited ? "status.rate_limited_cache" : "status.bundled_fallback", nil)
            }
            return ([], "status.unavailable", error)
        }
    }

    func setWallpaper(_ wallpaper: Wallpaper) async throws -> Wallpaper {
        let downloaded = try await downloader.downloadImage(for: wallpaper, quality: preferences.wallpaperQuality)
        guard let localURL = await localRepository.loadImageURL(for: downloaded) else {
            throw WallpaperServiceError.imageUnavailable
        }
        try await wallpaperSetter.setWallpaper(localURL, target: preferences.applyTarget, fitMode: preferences.fitMode)
        var updated = downloaded
        updated.lastUsedAt = Date()
        try await localRepository.updateWallpaper(updated)
        preferences.lastSelectedWallpaperId = updated.id
        preferences.lastChangeDate = Date()
        return updated
    }

    func toggleFavorite(_ wallpaper: Wallpaper) async throws -> Wallpaper {
        var updated = wallpaper
        updated.isFavorite.toggle()
        try await localRepository.updateWallpaper(updated)
        return updated
    }

    func downloadOriginal(_ wallpaper: Wallpaper) async throws -> Wallpaper {
        try await downloader.downloadImage(for: wallpaper, quality: preferences.wallpaperQuality)
    }

    func downloadThumbnail(_ wallpaper: Wallpaper) async throws -> Wallpaper {
        try await downloader.downloadThumbnail(for: wallpaper)
    }

    func clearThumbnails() async throws {
        try await localRepository.clearThumbnails()
    }

    func clearDownloadedImages() async throws {
        try await localRepository.clearDownloadedImages()
    }

    private func fetchRemote(source: WallpaperSource) async throws -> [Wallpaper] {
        if source == .mixed {
            return try await fetchMixedRemote()
        }

        if source == .bing {
            (repositories[.bing] as? BingMarketConfigurable)?.setMarket(preferences.bingMarket.rawValue)
        } else if source == .unsplash {
            (repositories[.unsplash] as? UnsplashCategoryConfigurable)?.setCategory(preferences.unsplashCategory)
        } else if source == .pexels {
            (repositories[.pexels] as? PexelsQueryConfigurable)?.setQuery(preferences.pexelsQuery)
        } else if source == .pixabay {
            (repositories[.pixabay] as? PixabayQueryConfigurable)?.setQuery(preferences.pixabayQuery)
        }

        guard let repository = repositories[source] else {
            throw WallpaperServiceError.repositoryUnavailable(source)
        }
        return try await repository.fetchLatest()
    }

    private func mergeWithLocalState(_ remote: [Wallpaper], source: WallpaperSource) async throws -> [Wallpaper] {
        let local = try await localState(for: source)
        let localById = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        return remote.map { wallpaper in
            guard let existing = localById[wallpaper.id] else { return wallpaper }
            var merged = wallpaper
            merged.localImagePath = existing.localImagePath
            merged.localThumbnailPath = existing.localThumbnailPath
            merged.isFavorite = existing.isFavorite
            merged.isDownloaded = existing.isDownloaded
            merged.lastUsedAt = existing.lastUsedAt
            merged.downloadedAt = existing.downloadedAt
            return merged
        }
    }

    private func fetchMixedRemote() async throws -> [Wallpaper] {
        let remoteSources = repositories.keys.filter { $0 != .mixed }
        var merged: [Wallpaper] = []
        var firstError: Error?

        for source in remoteSources {
            guard let repository = repositories[source] else { continue }
            if source == .bing {
                (repository as? BingMarketConfigurable)?.setMarket(preferences.bingMarket.rawValue)
            } else if source == .unsplash {
                (repository as? UnsplashCategoryConfigurable)?.setCategory(preferences.unsplashCategory)
            } else if source == .pexels {
                (repository as? PexelsQueryConfigurable)?.setQuery(preferences.pexelsQuery)
            } else if source == .pixabay {
                (repository as? PixabayQueryConfigurable)?.setQuery(preferences.pixabayQuery)
            }
            do {
                merged.append(contentsOf: try await repository.fetchLatest())
            } catch {
                if firstError == nil {
                    firstError = error
                }
            }
        }

        if merged.isEmpty {
            throw firstError ?? WallpaperServiceError.noWallpapersAvailable
        }

        let deduped = Dictionary(uniqueKeysWithValues: merged.map { ($0.id, $0) })
            .values
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
        return deduped
    }

    private func localState(for source: WallpaperSource) async throws -> [Wallpaper] {
        if source != .mixed {
            return try await localRepository.loadMetadata(source: source)
        }

        var map: [String: Wallpaper] = [:]
        for item in try await localRepository.loadMetadata(source: .mixed) {
            map[item.id] = item
        }
        for subSource in WallpaperSource.versionOneSources where subSource != .mixed {
            for item in try await localRepository.loadMetadata(source: subSource) {
                map[item.id] = item
            }
        }
        return Array(map.values)
    }

    private func sort(_ wallpapers: [Wallpaper]) -> [Wallpaper] {
        let filtered = preferences.favoritesOnly || preferences.shuffleMode == .favoritesOnly
            ? wallpapers.filter(\.isFavorite)
            : wallpapers

        switch preferences.shuffleMode {
        case .random:
            return filtered.shuffled()
        default:
            return filtered.sorted {
                ($0.date ?? .distantPast) > ($1.date ?? .distantPast)
            }
        }
    }

    private func isRateLimited(_ error: Error) -> Bool {
        if let network = error as? NetworkError {
            switch network {
            case .httpStatus(let code):
                return code == 429
            case .unknown(let message):
                return message.localizedCaseInsensitiveContains("rate limit")
                    || message.localizedCaseInsensitiveContains("cooldown")
            default:
                return false
            }
        }
        let description = error.localizedDescription.lowercased()
        return description.contains("429")
            || description.contains("rate limit")
            || description.contains("cooldown")
    }
}
