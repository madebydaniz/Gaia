import Foundation
import Testing
@testable import Gaia

struct WallpaperServiceTests {
    @Test @MainActor func fallsBackToLocalCacheWhenRemoteFails() async throws {
        let cached = makeWallpaper(id: "bing_cached")
        let local = InMemoryLocalWallpaperRepository()
        try await local.saveMetadata([cached], source: .bing)
        let service = makeService(
            repositories: [.bing: FailingWallpaperRepository(source: .bing)],
            localRepository: local
        )

        let result = await service.loadWallpapers(source: .bing)

        #expect(result.wallpapers == [cached])
        #expect(result.status == "Offline cache")
        #expect(result.error != nil)
    }

    @Test @MainActor func mixedSourceMergesBingAndGoogleEarth() async throws {
        let bing = makeWallpaper(id: "bing_1", source: .bing)
        let earth = makeWallpaper(id: "googleEarth_1", source: .googleEarth)
        let duplicatedBing = makeWallpaper(id: "bing_1", source: .bing)

        let service = makeService(
            repositories: [
                .bing: StaticWallpaperRepository(source: .bing, wallpapers: [bing, duplicatedBing]),
                .googleEarth: StaticWallpaperRepository(source: .googleEarth, wallpapers: [earth])
            ],
            localRepository: InMemoryLocalWallpaperRepository()
        )

        let result = await service.loadWallpapers(source: .mixed)

        #expect(result.status == "Updated today")
        #expect(result.error == nil)
        #expect(result.wallpapers.count == 2)
        #expect(Set(result.wallpapers.map(\.id)) == Set(["bing_1", "googleEarth_1"]))
    }

    @MainActor
    private func makeService(
        repositories: [WallpaperSource: WallpaperRepository],
        localRepository: WallpaperLocalRepository
    ) -> WallpaperService {
        let preferences = PreferencesService(defaults: UserDefaults(suiteName: "GaiaTests-\(UUID().uuidString)")!)
        return WallpaperService(
            repositories: repositories,
            localRepository: localRepository,
            downloader: NoopDownloader(),
            wallpaperSetter: NoopWallpaperSetter(),
            preferences: preferences,
            fallbackProvider: nil
        )
    }
}

func makeWallpaper(id: String, source: WallpaperSource = .bing) -> Wallpaper {
    Wallpaper(
        id: id,
        source: source,
        title: "Title \(id)",
        description: nil,
        imageURL: URL(string: "https://example.com/\(id).jpg"),
        thumbnailURL: URL(string: "https://example.com/\(id)-thumb.jpg"),
        sourcePageURL: nil,
        copyright: nil,
        locationName: nil,
        date: Date(timeIntervalSince1970: 1),
        width: 100,
        height: 100,
        localImagePath: nil,
        localThumbnailPath: nil,
        isFavorite: false,
        isDownloaded: false,
        lastUsedAt: nil,
        downloadedAt: nil
    )
}

struct StaticWallpaperRepository: WallpaperRepository {
    let source: WallpaperSource
    let wallpapers: [Wallpaper]

    func fetchLatest() async throws -> [Wallpaper] { wallpapers }
    func fetchRandom() async throws -> Wallpaper? { wallpapers.randomElement() }
    func fetchById(_ id: String) async throws -> Wallpaper? { wallpapers.first { $0.id == id } }
}

struct FailingWallpaperRepository: WallpaperRepository {
    let source: WallpaperSource

    func fetchLatest() async throws -> [Wallpaper] { throw NetworkError.offline }
    func fetchRandom() async throws -> Wallpaper? { throw NetworkError.offline }
    func fetchById(_ id: String) async throws -> Wallpaper? { throw NetworkError.offline }
}

final class InMemoryLocalWallpaperRepository: WallpaperLocalRepository {
    private var storage: [WallpaperSource: [Wallpaper]] = [:]

    func saveMetadata(_ wallpapers: [Wallpaper], source: WallpaperSource) async throws {
        storage[source] = wallpapers
    }

    func loadMetadata(source: WallpaperSource?) async throws -> [Wallpaper] {
        if let source, source.isAvailableInVersionOne {
            return storage[source] ?? []
        }
        return storage.values.flatMap { $0 }
    }

    func updateWallpaper(_ wallpaper: Wallpaper) async throws {
        var wallpapers = storage[wallpaper.source] ?? []
        if let index = wallpapers.firstIndex(where: { $0.id == wallpaper.id }) {
            wallpapers[index] = wallpaper
        } else {
            wallpapers.append(wallpaper)
        }
        storage[wallpaper.source] = wallpapers
    }

    func saveImage(data: Data, for wallpaper: Wallpaper) async throws -> URL {
        URL(fileURLWithPath: "/tmp/\(wallpaper.id).jpg")
    }

    func saveThumbnail(data: Data, for wallpaper: Wallpaper) async throws -> URL {
        URL(fileURLWithPath: "/tmp/\(wallpaper.id)-thumb.jpg")
    }

    func loadImageURL(for wallpaper: Wallpaper) async -> URL? {
        wallpaper.localImagePath.map(URL.init(fileURLWithPath:))
    }

    func clearThumbnails() async throws {}
    func clearDownloadedImages() async throws {}
}

struct NoopDownloader: WallpaperImageDownloader {
    func downloadImage(for wallpaper: Wallpaper, quality: WallpaperQuality) async throws -> Wallpaper { wallpaper }
    func downloadThumbnail(for wallpaper: Wallpaper) async throws -> Wallpaper { wallpaper }
}

struct NoopWallpaperSetter: WallpaperSetter {
    func setWallpaper(_ fileURL: URL, target: WallpaperApplyTarget, fitMode: WallpaperFitMode) async throws {}
}
