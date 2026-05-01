import Foundation
import Testing
@testable import Gaia

struct LocalWallpaperRepositoryTests {
    @Test func updateWallpaperPersistsFavoriteState() async throws {
        let repository = try makeRepository()
        var wallpaper = makeWallpaper(id: "bing_test")
        try await repository.saveMetadata([wallpaper], source: .bing)

        wallpaper.isFavorite = true
        try await repository.updateWallpaper(wallpaper)

        let loaded = try await repository.loadMetadata(source: .bing)
        #expect(loaded.first?.isFavorite == true)
    }

    private func makeRepository() throws -> LocalWallpaperRepository {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("GaiaTests-\(UUID().uuidString)", isDirectory: true)
        let storage = FileStorage(rootURL: root)
        let metadataStore = MetadataStore(fileStorage: storage)
        return LocalWallpaperRepository(fileStorage: storage, metadataStore: metadataStore)
    }
}
