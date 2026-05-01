import Foundation

protocol WallpaperRepository {
    var source: WallpaperSource { get }

    func fetchLatest() async throws -> [Wallpaper]
    func fetchRandom() async throws -> Wallpaper?
    func fetchById(_ id: String) async throws -> Wallpaper?
}
