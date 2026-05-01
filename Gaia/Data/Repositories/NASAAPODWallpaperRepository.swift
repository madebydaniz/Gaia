import Foundation

final class NASAAPODWallpaperRepository: WallpaperRepository {
    let source: WallpaperSource = .nasaAPOD
    private let httpClient: HTTPClient
    private let apiKey: String

    init(httpClient: HTTPClient, apiKey: String = "DEMO_KEY") {
        self.httpClient = httpClient
        self.apiKey = apiKey
    }

    func fetchLatest() async throws -> [Wallpaper] {
        guard var components = URLComponents(string: "https://api.nasa.gov/planetary/apod") else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "count", value: "12")
        ]
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        let dtos = try await httpClient.decoded([NASAAPODDTO].self, from: Endpoint(url: url), decoder: JSONDecoder())
        return dtos
            .filter { $0.mediaType == "image" }
            .map { $0.toDomain() }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    func fetchRandom() async throws -> Wallpaper? {
        try await fetchLatest().randomElement()
    }

    func fetchById(_ id: String) async throws -> Wallpaper? {
        try await fetchLatest().first { $0.id == id }
    }
}

private struct NASAAPODDTO: Decodable, Sendable {
    let date: String
    let title: String?
    let explanation: String?
    let url: URL?
    let hdurl: URL?
    let mediaType: String
    let copyright: String?

    enum CodingKeys: String, CodingKey {
        case date
        case title
        case explanation
        case url
        case hdurl
        case mediaType = "media_type"
        case copyright
    }

    func toDomain() -> Wallpaper {
        Wallpaper(
            id: "nasaAPOD_\(date.sanitizedFileName)",
            source: .nasaAPOD,
            title: title ?? "NASA APOD",
            description: explanation,
            imageURL: hdurl ?? url,
            thumbnailURL: url,
            sourcePageURL: nil,
            copyright: copyright ?? "NASA",
            locationName: nil,
            date: Self.dateFormatter.date(from: date),
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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
