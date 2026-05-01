import Foundation
import Testing
@testable import Gaia

struct FileStorageTests {
    @Test func prepareDirectoriesCreatesExpectedLayout() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("GaiaFileStorageTests-\(UUID().uuidString)", isDirectory: true)
        let storage = FileStorage(rootURL: root)

        try storage.prepareDirectories()

        #expect(FileManager.default.fileExists(atPath: storage.metadataDirectory.path))
        #expect(FileManager.default.fileExists(atPath: storage.imagesDirectory(for: .bing).path))
        #expect(FileManager.default.fileExists(atPath: storage.thumbnailsDirectory(for: .googleEarth).path))
        #expect(FileManager.default.fileExists(atPath: storage.logsDirectory.path))
    }
}
