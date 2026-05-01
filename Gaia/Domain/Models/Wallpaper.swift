import Foundation

struct Wallpaper: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let source: WallpaperSource
    let title: String?
    let description: String?
    let imageURL: URL?
    let thumbnailURL: URL?
    let sourcePageURL: URL?
    let copyright: String?
    let locationName: String?
    let date: Date?
    let width: Int?
    let height: Int?

    var localImagePath: String?
    var localThumbnailPath: String?
    var isFavorite: Bool
    var isDownloaded: Bool
    var lastUsedAt: Date?
    var downloadedAt: Date?

    var displayTitle: String {
        title ?? locationName ?? source.displayName
    }
}
