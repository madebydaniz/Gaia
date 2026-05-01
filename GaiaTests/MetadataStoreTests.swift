import Foundation
import Testing
@testable import Gaia

struct MetadataStoreTests {
    @Test func savesAndLoadsMetadata() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("GaiaMetadataTests-\(UUID().uuidString)", isDirectory: true)
        let storage = FileStorage(rootURL: root)
        let store = MetadataStore(fileStorage: storage)
        let wallpaper = makeWallpaper(id: "googleEarth_sample", source: .googleEarth)

        try await store.save([wallpaper], source: .googleEarth)
        let loaded = try await store.load(source: .googleEarth)

        #expect(loaded == [wallpaper])
    }
}
