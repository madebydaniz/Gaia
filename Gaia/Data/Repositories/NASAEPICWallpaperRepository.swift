import Foundation

final class NASAEPICWallpaperRepository: WallpaperRepository {
    let source: WallpaperSource = .nasaEPIC
    private let httpClient: HTTPClient
    private let apiKey: String

    init(httpClient: HTTPClient, apiKey: String = "DEMO_KEY") {
        self.httpClient = httpClient
        self.apiKey = apiKey
    }

    func fetchLatest() async throws -> [Wallpaper] {
        guard var components = URLComponents(string: "https://api.nasa.gov/EPIC/api/natural") else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        let dtos = try await httpClient.decoded([NASAEPICDTO].self, from: Endpoint(url: url), decoder: JSONDecoder())
        return dtos.map { $0.toDomain(apiKey: apiKey) }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    func fetchRandom() async throws -> Wallpaper? {
        try await fetchLatest().randomElement()
    }

    func fetchById(_ id: String) async throws -> Wallpaper? {
        try await fetchLatest().first { $0.id == id }
    }
}

private struct NASAEPICDTO: Decodable, Sendable {
    let identifier: String
    let caption: String?
    let image: String
    let date: String

    func toDomain(apiKey: String) -> Wallpaper {
        let dayPath = date.prefix(10).replacingOccurrences(of: "-", with: "/")
        let imageURL = URL(string: "https://api.nasa.gov/EPIC/archive/natural/\(dayPath)/png/\(image).png?api_key=\(apiKey)")
        let thumbURL = URL(string: "https://api.nasa.gov/EPIC/archive/natural/\(dayPath)/thumbs/\(image).jpg?api_key=\(apiKey)")

        return Wallpaper(
            id: "nasaEPIC_\(identifier.sanitizedFileName)",
            source: .nasaEPIC,
            title: "NASA EPIC \(identifier)",
            description: caption,
            imageURL: imageURL,
            thumbnailURL: thumbURL,
            sourcePageURL: URL(string: "https://epic.gsfc.nasa.gov/"),
            copyright: "NASA EPIC / DSCOVR",
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
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
