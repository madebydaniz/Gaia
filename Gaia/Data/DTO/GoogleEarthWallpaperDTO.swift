import Foundation

struct GoogleEarthWallpaperDTO: Codable, Sendable {
    let id: String
    let title: String?
    let description: String?
    let locationName: String?
    let imageURL: URL?
    let thumbnailURL: URL?
    let sourcePageURL: URL?
    let width: Int?
    let height: Int?
    let copyright: String?
    let region: String?
    let country: String?
    let map: URL?
    let image: URL?
    let attribution: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case locationName
        case imageURL
        case thumbnailURL
        case sourcePageURL
        case width
        case height
        case copyright
        case region
        case country
        case map
        case image
        case attribution
    }

    func toDomain() -> Wallpaper {
        let resolvedLocation = locationName ?? [region, country]
            .compactMap { $0?.nilIfEmpty }
            .joined(separator: ", ")
            .nilIfEmpty
        let resolvedTitle = title ?? resolvedLocation ?? "Earth View \(id)"
        let resolvedImageURL = imageURL ?? image

        return Wallpaper(
            id: "googleEarth_\(id.sanitizedFileName)",
            source: .googleEarth,
            title: resolvedTitle,
            description: description,
            imageURL: resolvedImageURL,
            thumbnailURL: thumbnailURL,
            sourcePageURL: sourcePageURL ?? map,
            copyright: copyright ?? attribution ?? "Google Earth",
            locationName: resolvedLocation,
            date: nil,
            width: width,
            height: height,
            localImagePath: nil,
            localThumbnailPath: nil,
            isFavorite: false,
            isDownloaded: false,
            lastUsedAt: nil,
            downloadedAt: nil
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
