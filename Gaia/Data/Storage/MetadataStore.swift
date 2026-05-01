import Foundation

final class MetadataStore {
    private let fileStorage: FileStorage
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileStorage: FileStorage) {
        self.fileStorage = fileStorage
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func save(_ wallpapers: [Wallpaper], source: WallpaperSource) async throws {
        try fileStorage.prepareDirectories()
        let data = try encoder.encode(wallpapers)
        try data.write(to: fileStorage.metadataURL(for: source), options: .atomic)
    }

    func load(source: WallpaperSource) async throws -> [Wallpaper] {
        try fileStorage.prepareDirectories()
        let url = fileStorage.metadataURL(for: source)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode([Wallpaper].self, from: data)
    }

    func loadAll() async throws -> [Wallpaper] {
        var result: [Wallpaper] = []
        for source in WallpaperSource.cacheableSources {
            result.append(contentsOf: try await load(source: source))
        }
        return result
    }
}
