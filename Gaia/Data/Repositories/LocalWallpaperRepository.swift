import Foundation

final class LocalWallpaperRepository: WallpaperLocalRepository {
    private let fileStorage: FileStorage
    private let metadataStore: MetadataStore

    init(fileStorage: FileStorage, metadataStore: MetadataStore) {
        self.fileStorage = fileStorage
        self.metadataStore = metadataStore
    }

    func saveMetadata(_ wallpapers: [Wallpaper], source: WallpaperSource) async throws {
        try await metadataStore.save(wallpapers, source: source)
    }

    func loadMetadata(source: WallpaperSource?) async throws -> [Wallpaper] {
        if let source {
            return try await metadataStore.load(source: source)
        }
        return try await metadataStore.loadAll()
    }

    func updateWallpaper(_ wallpaper: Wallpaper) async throws {
        var wallpapers = try await metadataStore.load(source: wallpaper.source)
        if let index = wallpapers.firstIndex(where: { $0.id == wallpaper.id }) {
            wallpapers[index] = wallpaper
        } else {
            wallpapers.append(wallpaper)
        }
        try await metadataStore.save(wallpapers, source: wallpaper.source)
    }

    func saveImage(data: Data, for wallpaper: Wallpaper) async throws -> URL {
        try fileStorage.prepareDirectories()
        let url = fileStorage.imageURL(for: wallpaper, fileExtension: imageExtension(for: wallpaper.imageURL))
        try data.write(to: url, options: .atomic)
        return url
    }

    func saveThumbnail(data: Data, for wallpaper: Wallpaper) async throws -> URL {
        try fileStorage.prepareDirectories()
        let url = fileStorage.thumbnailURL(for: wallpaper, fileExtension: imageExtension(for: wallpaper.thumbnailURL))
        try data.write(to: url, options: .atomic)
        return url
    }

    func loadImageURL(for wallpaper: Wallpaper) async -> URL? {
        if let path = wallpaper.localImagePath {
            let url = URL(fileURLWithPath: path)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
        let url = fileStorage.imageURL(for: wallpaper)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func clearThumbnails() async throws {
        try fileStorage.prepareDirectories()
        for source in WallpaperSource.cacheableSources {
            try fileStorage.removeContents(of: fileStorage.thumbnailsDirectory(for: source))
        }
    }

    func clearDownloadedImages() async throws {
        try fileStorage.prepareDirectories()
        for source in WallpaperSource.cacheableSources {
            try fileStorage.removeContents(of: fileStorage.imagesDirectory(for: source))
        }
    }

    private func imageExtension(for url: URL?) -> String {
        let ext = url?.pathExtension.lowercased()
        return ext?.isEmpty == false ? ext! : "jpg"
    }
}
