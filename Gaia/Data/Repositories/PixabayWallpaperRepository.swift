import Foundation

protocol PixabayQueryConfigurable {
    func setQuery(_ query: String)
}

final class PixabayWallpaperRepository: WallpaperRepository {
    let source: WallpaperSource = .pixabay
    private let httpClient: HTTPClient
    private let apiKey: String?
    private var query: String

    init(httpClient: HTTPClient, apiKey: String?, query: String = AppConfig.Defaults.pixabayQuery) {
        self.httpClient = httpClient
        self.apiKey = apiKey
        self.query = query
    }

    func fetchLatest() async throws -> [Wallpaper] {
        guard let apiKey, !apiKey.isEmpty else {
            throw NetworkError.unknown("Pixabay API key is missing.")
        }
        guard var components = URLComponents(string: "https://pixabay.com/api/") else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "image_type", value: "photo"),
            URLQueryItem(name: "orientation", value: "horizontal"),
            URLQueryItem(name: "safesearch", value: "true"),
            URLQueryItem(name: "min_width", value: "1920"),
            URLQueryItem(name: "per_page", value: "50")
        ]
        guard let url = components.url else { throw NetworkError.invalidURL }
        let response = try await httpClient.decoded(PixabayResponseDTO.self, from: Endpoint(url: url), decoder: JSONDecoder())
        return response.hits.map { $0.toDomain() }
    }

    func fetchRandom() async throws -> Wallpaper? {
        try await fetchLatest().randomElement()
    }

    func fetchById(_ id: String) async throws -> Wallpaper? {
        try await fetchLatest().first { $0.id == id }
    }
}

extension PixabayWallpaperRepository: PixabayQueryConfigurable {
    func setQuery(_ query: String) {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        self.query = normalized.isEmpty ? "landscape" : normalized
    }
}

private struct PixabayResponseDTO: Decodable, Sendable {
    let hits: [PixabayHitDTO]
}

private struct PixabayHitDTO: Decodable, Sendable {
    let id: Int
    let tags: String?
    let user: String?
    let pageURL: URL?
    let largeImageURL: URL?
    let fullHDURL: URL?
    let webformatURL: URL?
    let previewURL: URL?
    let imageWidth: Int?
    let imageHeight: Int?

    func toDomain() -> Wallpaper {
        Wallpaper(
            id: "pixabay_\(id)",
            source: .pixabay,
            title: tags?.split(separator: ",").first.map(String.init)?.nilIfEmpty ?? user?.nilIfEmpty ?? "Pixabay",
            description: tags,
            imageURL: fullHDURL ?? largeImageURL ?? webformatURL,
            thumbnailURL: webformatURL ?? previewURL,
            sourcePageURL: pageURL,
            copyright: user.map { "\($0) / Pixabay" } ?? "Pixabay",
            locationName: nil,
            date: nil,
            width: imageWidth,
            height: imageHeight,
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
