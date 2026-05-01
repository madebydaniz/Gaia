import Foundation

final class PicsumWallpaperRepository: WallpaperRepository {
    let source: WallpaperSource = .picsum
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchLatest() async throws -> [Wallpaper] {
        guard let url = URL(string: "https://picsum.photos/v2/list?page=1&limit=40") else {
            throw NetworkError.invalidURL
        }
        let dtos = try await httpClient.decoded([PicsumDTO].self, from: Endpoint(url: url), decoder: JSONDecoder())
        return dtos.map { $0.toDomain() }
    }

    func fetchRandom() async throws -> Wallpaper? {
        try await fetchLatest().randomElement()
    }

    func fetchById(_ id: String) async throws -> Wallpaper? {
        try await fetchLatest().first { $0.id == id }
    }
}

private struct PicsumDTO: Decodable, Sendable {
    let id: String
    let author: String?
    let width: Int?
    let height: Int?
    let url: URL?
    let downloadURL: URL?

    enum CodingKeys: String, CodingKey {
        case id, author, width, height, url
        case downloadURL = "download_url"
    }

    func toDomain() -> Wallpaper {
        let fullURL = URL(string: "https://picsum.photos/id/\(id)/3840/2160")
        let thumbURL = URL(string: "https://picsum.photos/id/\(id)/900/506")
        return Wallpaper(
            id: "picsum_\(id.sanitizedFileName)",
            source: .picsum,
            title: "Picsum Photo",
            description: author,
            imageURL: fullURL ?? downloadURL,
            thumbnailURL: thumbURL,
            sourcePageURL: url,
            copyright: author.map { "\($0) / Lorem Picsum" } ?? "Lorem Picsum",
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
