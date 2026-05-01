import Foundation

protocol WallpaperSetter {
    func setWallpaper(_ fileURL: URL, target: WallpaperApplyTarget, fitMode: WallpaperFitMode) async throws
}
