import Foundation

protocol WallpaperLocalRepository {
    func saveMetadata(_ wallpapers: [Wallpaper], source: WallpaperSource) async throws
    func loadMetadata(source: WallpaperSource?) async throws -> [Wallpaper]
    func updateWallpaper(_ wallpaper: Wallpaper) async throws
    func saveImage(data: Data, for wallpaper: Wallpaper) async throws -> URL
    func saveThumbnail(data: Data, for wallpaper: Wallpaper) async throws -> URL
    func loadImageURL(for wallpaper: Wallpaper) async -> URL?
    func clearThumbnails() async throws
    func clearDownloadedImages() async throws
}
