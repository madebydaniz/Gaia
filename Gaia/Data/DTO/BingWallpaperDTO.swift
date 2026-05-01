import Foundation

struct BingWallpaperResponseDTO: Decodable, Sendable {
    let images: [BingWallpaperDTO]
}

struct BingWallpaperDTO: Decodable, Sendable {
    let startdate: String
    let fullstartdate: String?
    let enddate: String?
    let url: String
    let urlbase: String?
    let copyright: String?
    let copyrightlink: String?
    let title: String?
    let hsh: String?

    func toDomain() -> Wallpaper {
        let idSeed = hsh ?? urlbase ?? startdate
        let id = "bing_\(idSeed.sanitizedFileName)"
        let imageURL = URL(string: absoluteBingURL(path: url))
        let thumbnailURL = URL(string: absoluteBingURL(path: "\(urlbase ?? url)_400x240.jpg"))
        let sourcePageURL = normalizedSourcePageURL(copyrightlink)
        let resolvedTitle = title?.nilIfEmpty ?? copyrightTitle(from: copyright) ?? "Bing Wallpaper"

        return Wallpaper(
            id: id,
            source: .bing,
            title: resolvedTitle,
            description: copyright,
            imageURL: imageURL,
            thumbnailURL: thumbnailURL,
            sourcePageURL: sourcePageURL,
            copyright: copyright,
            locationName: nil,
            date: Self.dateFormatter.date(from: startdate),
            width: nil,
            height: nil,
            localImagePath: nil,
            localThumbnailPath: nil,
            isFavorite: false,
            isDownloaded: false,
            lastUsedAt: nil,
            downloadedAt: nil
        )
    }

    private func absoluteBingURL(path: String) -> String {
        if path.hasPrefix("http") {
            return path
        }
        return "https://www.bing.com\(path)"
    }

    private func normalizedSourcePageURL(_ link: String?) -> URL? {
        guard let link, !link.isEmpty else { return nil }
        if link.hasPrefix("javascript") || link == "1" {
            return nil
        }
        if link.hasPrefix("http") {
            return URL(string: link)
        }
        return URL(string: absoluteBingURL(path: link))
    }

    private func copyrightTitle(from text: String?) -> String? {
        guard let text, let range = text.range(of: " (") else { return text?.nilIfEmpty }
        return String(text[..<range.lowerBound]).nilIfEmpty
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
