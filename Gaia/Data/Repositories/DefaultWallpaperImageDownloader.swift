import Foundation

final class DefaultWallpaperImageDownloader: WallpaperImageDownloader {
    private let httpClient: HTTPClient
    private let localRepository: WallpaperLocalRepository
    private let thumbnailGenerator: ThumbnailGenerator

    init(
        httpClient: HTTPClient,
        localRepository: WallpaperLocalRepository,
        thumbnailGenerator: ThumbnailGenerator
    ) {
        self.httpClient = httpClient
        self.localRepository = localRepository
        self.thumbnailGenerator = thumbnailGenerator
    }

    func downloadImage(for wallpaper: Wallpaper, quality: WallpaperQuality) async throws -> Wallpaper {
        if let existing = await localRepository.loadImageURL(for: wallpaper) {
            var updated = wallpaper
            updated.localImagePath = existing.path
            updated.isDownloaded = true
            return updated
        }

        guard let remoteURL = imageURL(for: wallpaper, quality: quality) else {
            throw ImageCacheError.missingRemoteURL
        }
        let (data, response) = try await httpClient.data(from: Endpoint(url: remoteURL, timeout: 45))
        try validateImage(response: response)
        let localURL = try await localRepository.saveImage(data: data, for: wallpaper)
        var updated = wallpaper
        updated.localImagePath = localURL.path
        updated.isDownloaded = true
        updated.downloadedAt = Date()

        if updated.localThumbnailPath == nil {
            if let thumbnailURL = try? await thumbnailGenerator.generateThumbnail(from: localURL, for: updated) {
                updated.localThumbnailPath = thumbnailURL.path
            }
        }
        try await localRepository.updateWallpaper(updated)
        return updated
    }

    func downloadThumbnail(for wallpaper: Wallpaper) async throws -> Wallpaper {
        if wallpaper.localThumbnailPath != nil {
            return wallpaper
        }
        guard let url = wallpaper.thumbnailURL ?? wallpaper.imageURL else {
            throw ImageCacheError.missingRemoteURL
        }
        let (data, response) = try await httpClient.data(from: Endpoint(url: url, timeout: 30))
        try validateImage(response: response)
        let localURL = try await localRepository.saveThumbnail(data: data, for: wallpaper)
        var updated = wallpaper
        updated.localThumbnailPath = localURL.path
        try await localRepository.updateWallpaper(updated)
        return updated
    }

    private func imageURL(for wallpaper: Wallpaper, quality: WallpaperQuality) -> URL? {
        guard let imageURL = wallpaper.imageURL else { return nil }
        guard wallpaper.source == .bing, quality == .uhd else { return imageURL }
        let absolute = imageURL.absoluteString
        if absolute.contains("_1920x1080") {
            return URL(string: absolute.replacingOccurrences(of: "_1920x1080", with: "_UHD"))
        }
        return imageURL
    }

    private func validateImage(response: HTTPURLResponse) throws {
        let mimeType = response.mimeType?.lowercased()
        guard mimeType?.hasPrefix("image/") == true || mimeType == nil else {
            throw ImageCacheError.unsupportedMimeType(mimeType)
        }
    }
}
