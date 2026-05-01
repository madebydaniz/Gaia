import Foundation

protocol PexelsQueryConfigurable {
    func setQuery(_ query: String)
}

final class PexelsWallpaperRepository: WallpaperRepository {
    let source: WallpaperSource = .pexels
    private let httpClient: HTTPClient
    private let apiKey: String?
    private var query: String

    init(httpClient: HTTPClient, apiKey: String?, query: String = AppConfig.Defaults.pexelsQuery) {
        self.httpClient = httpClient
        self.apiKey = apiKey
        self.query = query
    }

    func fetchLatest() async throws -> [Wallpaper] {
        guard let apiKey, !apiKey.isEmpty else {
            throw NetworkError.unknown("Pexels API key is missing.")
        }
        guard var components = URLComponents(string: "https://api.pexels.com/v1/search") else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "orientation", value: "landscape"),
            URLQueryItem(name: "per_page", value: "40")
        ]
        guard let url = components.url else { throw NetworkError.invalidURL }
        let endpoint = Endpoint(url: url, headers: ["Authorization": apiKey])
        let response = try await httpClient.decoded(PexelsResponseDTO.self, from: endpoint, decoder: JSONDecoder())
        return response.photos.map { $0.toDomain() }
    }

    func fetchRandom() async throws -> Wallpaper? {
        try await fetchLatest().randomElement()
    }

    func fetchById(_ id: String) async throws -> Wallpaper? {
        try await fetchLatest().first { $0.id == id }
    }
}

extension PexelsWallpaperRepository: PexelsQueryConfigurable {
    func setQuery(_ query: String) {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        self.query = normalized.isEmpty ? "nature" : normalized
    }
}

private struct PexelsResponseDTO: Decodable, Sendable {
    let photos: [PexelsPhotoDTO]
}

private struct PexelsPhotoDTO: Decodable, Sendable {
    let id: Int
    let width: Int?
    let height: Int?
    let url: URL?
    let photographer: String?
    let alt: String?
    let src: PexelsPhotoSourceDTO

    func toDomain() -> Wallpaper {
        Wallpaper(
            id: "pexels_\(id)",
            source: .pexels,
            title: alt?.nilIfEmpty ?? photographer?.nilIfEmpty ?? "Pexels",
            description: alt,
            imageURL: src.original ?? src.large2x ?? src.large,
            thumbnailURL: src.medium ?? src.small ?? src.tiny,
            sourcePageURL: url,
            copyright: photographer.map { "\($0) / Pexels" } ?? "Pexels",
            locationName: nil,
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

private struct PexelsPhotoSourceDTO: Decodable, Sendable {
    let original: URL?
    let large2x: URL?
    let large: URL?
    let medium: URL?
    let small: URL?
    let tiny: URL?
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
