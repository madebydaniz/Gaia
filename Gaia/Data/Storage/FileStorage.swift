import Foundation

enum FileStorageError: Error, LocalizedError {
    case applicationSupportUnavailable

    var errorDescription: String? {
        switch self {
        case .applicationSupportUnavailable: "Application Support folder is unavailable."
        }
    }
}

final class FileStorage {
    private let fileManager: FileManager
    let rootURL: URL

    init(fileManager: FileManager = .default, rootURL: URL? = nil) {
        self.fileManager = fileManager
        if let rootURL {
            self.rootURL = rootURL
        } else {
            let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            self.rootURL = (supportURL ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent("Gaia", isDirectory: true)
        }
    }

    func prepareDirectories() throws {
        try createDirectory(rootURL)
        try createDirectory(metadataDirectory)
        for source in WallpaperSource.cacheableSources {
            try createDirectory(imagesDirectory(for: source))
            try createDirectory(thumbnailsDirectory(for: source))
        }
        try createDirectory(logsDirectory)
    }

    var metadataDirectory: URL {
        rootURL.appendingPathComponent("metadata", isDirectory: true)
    }

    var logsDirectory: URL {
        rootURL.appendingPathComponent("logs", isDirectory: true)
    }

    func metadataURL(for source: WallpaperSource) -> URL {
        metadataDirectory.appendingPathComponent("\(source.storageName).json")
    }

    func imagesDirectory(for source: WallpaperSource) -> URL {
        rootURL.appendingPathComponent("images", isDirectory: true).appendingPathComponent(source.storageName, isDirectory: true)
    }

    func thumbnailsDirectory(for source: WallpaperSource) -> URL {
        rootURL.appendingPathComponent("thumbnails", isDirectory: true).appendingPathComponent(source.storageName, isDirectory: true)
    }

    func imageURL(for wallpaper: Wallpaper, fileExtension: String = "jpg") -> URL {
        imagesDirectory(for: wallpaper.source).appendingPathComponent("\(wallpaper.id.sanitizedFileName).\(fileExtension)")
    }

    func thumbnailURL(for wallpaper: Wallpaper, fileExtension: String = "jpg") -> URL {
        thumbnailsDirectory(for: wallpaper.source).appendingPathComponent("\(wallpaper.id.sanitizedFileName).\(fileExtension)")
    }

    func createDirectory(_ url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func removeContents(of url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        for item in contents {
            try fileManager.removeItem(at: item)
        }
    }
}
