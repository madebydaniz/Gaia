import Foundation

final class WikimediaCommonsWallpaperRepository: WallpaperRepository {
    let source: WallpaperSource = .wikimediaCommons
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchLatest() async throws -> [Wallpaper] {
        guard var components = URLComponents(string: "https://commons.wikimedia.org/w/api.php") else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "generator", value: "categorymembers"),
            URLQueryItem(name: "gcmtitle", value: "Category:Featured pictures on Wikimedia Commons"),
            URLQueryItem(name: "gcmtype", value: "file"),
            URLQueryItem(name: "gcmlimit", value: "40"),
            URLQueryItem(name: "prop", value: "imageinfo"),
            URLQueryItem(name: "iiprop", value: "url|size|extmetadata"),
            URLQueryItem(name: "iiurlwidth", value: "900")
        ]
        guard let url = components.url else { throw NetworkError.invalidURL }
        let response = try await httpClient.decoded(WikimediaResponseDTO.self, from: Endpoint(url: url), decoder: JSONDecoder())
        return response.query.pages.values.compactMap { $0.toDomain() }
            .filter { $0.width ?? 0 >= 1600 && $0.height ?? 0 >= 900 }
    }

    func fetchRandom() async throws -> Wallpaper? {
        try await fetchLatest().randomElement()
    }

    func fetchById(_ id: String) async throws -> Wallpaper? {
        try await fetchLatest().first { $0.id == id }
    }
}

private struct WikimediaResponseDTO: Decodable, Sendable {
    struct Query: Decodable, Sendable {
        let pages: [String: WikimediaPageDTO]
    }
    let query: Query
}

private struct WikimediaPageDTO: Decodable, Sendable {
    let pageid: Int?
    let title: String
    let imageinfo: [WikimediaImageInfoDTO]?

    func toDomain() -> Wallpaper? {
        guard let info = imageinfo?.first, let imageURL = info.url else {
            return nil
        }
        let attribution = [info.extmetadata?.artist?.value, info.extmetadata?.licenseShortName?.value]
            .compactMap { $0?.strippedHTML }
            .compactMap { $0.nilIfEmpty }
            .joined(separator: " - ")
            .nilIfEmpty

        return Wallpaper(
            id: "wikimediaCommons_\(String(pageid ?? title.hashValue).sanitizedFileName)",
            source: .wikimediaCommons,
            title: title.replacingOccurrences(of: "File:", with: ""),
            description: info.extmetadata?.imageDescription?.value?.strippedHTML,
            imageURL: imageURL,
            thumbnailURL: info.thumburl,
            sourcePageURL: URL(string: "https://commons.wikimedia.org/wiki/\(title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title)"),
            copyright: attribution ?? "Wikimedia Commons",
            locationName: nil,
            date: nil,
            width: info.width,
            height: info.height,
            localImagePath: nil,
            localThumbnailPath: nil,
            isFavorite: false,
            isDownloaded: false,
            lastUsedAt: nil,
            downloadedAt: nil
        )
    }
}

private struct WikimediaImageInfoDTO: Decodable, Sendable {
    let url: URL?
    let thumburl: URL?
    let width: Int?
    let height: Int?
    let extmetadata: WikimediaExtMetadataDTO?
}

private struct WikimediaExtMetadataDTO: Decodable, Sendable {
    struct Value: Decodable, Sendable { let value: String? }
    let artist: Value?
    let imageDescription: Value?
    let licenseShortName: Value?

    enum CodingKeys: String, CodingKey {
        case artist = "Artist"
        case imageDescription = "ImageDescription"
        case licenseShortName = "LicenseShortName"
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }

    var strippedHTML: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
