import Foundation

protocol WallpaperImageDownloader {
    func downloadImage(for wallpaper: Wallpaper, quality: WallpaperQuality) async throws -> Wallpaper
    func downloadThumbnail(for wallpaper: Wallpaper) async throws -> Wallpaper
}
