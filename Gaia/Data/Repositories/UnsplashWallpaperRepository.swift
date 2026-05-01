import Foundation

protocol UnsplashCategoryConfigurable {
    func setCategory(_ category: String)
}

final class UnsplashWallpaperRepository: WallpaperRepository {
    let source: WallpaperSource = .unsplash
    private let httpClient: HTTPClient
    private let accessKey: String?
    private let throttler = UnsplashRequestThrottler.shared
    private var category: String

    init(httpClient: HTTPClient, accessKey: String?, category: String = AppConfig.Defaults.unsplashCategory) {
        self.httpClient = httpClient
        self.accessKey = accessKey
        self.category = category
    }

    func fetchLatest() async throws -> [Wallpaper] {
        guard let accessKey, !accessKey.isEmpty else {
            throw NetworkError.unknown("Unsplash access key is missing.")
        }
        try await throttler.checkAllowance()

        guard var components = URLComponents(string: "https://api.unsplash.com/search/photos") else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "query", value: category),
            URLQueryItem(name: "orientation", value: "landscape"),
            URLQueryItem(name: "content_filter", value: "high"),
            URLQueryItem(name: "per_page", value: "30")
        ]
        guard let url = components.url else { throw NetworkError.invalidURL }
        let endpoint = Endpoint(url: url, headers: [
            "Authorization": "Client-ID \(accessKey)",
            "Accept-Version": "v1"
        ])
        let (data, response) = try await httpClient.data(from: endpoint)
        await throttler.recordResponse(response)
        let result = try JSONDecoder().decode(UnsplashSearchResponseDTO.self, from: data)
        return result.results.map { $0.toDomain() }
    }

    func fetchRandom() async throws -> Wallpaper? {
        try await fetchLatest().randomElement()
    }

    func fetchById(_ id: String) async throws -> Wallpaper? {
        try await fetchLatest().first { $0.id == id }
    }
}

extension UnsplashWallpaperRepository: UnsplashCategoryConfigurable {
    func setCategory(_ category: String) {
        self.category = category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppConfig.Defaults.unsplashCategory : category
    }
}

private actor UnsplashRequestThrottler {
    static let shared = UnsplashRequestThrottler()

    private var nextAllowedAt: Date = .distantPast
    private let minimumInterval: TimeInterval = 8

    func checkAllowance(now: Date = .init()) throws {
        guard now >= nextAllowedAt else {
            throw NetworkError.unknown("Unsplash cooldown active. Using local cache.")
        }
        nextAllowedAt = now.addingTimeInterval(minimumInterval)
    }

    func recordResponse(_ response: HTTPURLResponse, now: Date = .init()) {
        if let remainingRaw = response.value(forHTTPHeaderField: "X-Ratelimit-Remaining"),
           let remaining = Int(remainingRaw),
           remaining <= 0,
           let resetRaw = response.value(forHTTPHeaderField: "X-Ratelimit-Reset"),
           let resetEpoch = TimeInterval(resetRaw) {
            nextAllowedAt = Date(timeIntervalSince1970: resetEpoch)
            return
        }

        if response.statusCode == 429 {
            nextAllowedAt = now.addingTimeInterval(60)
        }
    }
}

private struct UnsplashSearchResponseDTO: Decodable, Sendable {
    let results: [UnsplashPhotoDTO]
}

private struct UnsplashPhotoDTO: Decodable, Sendable {
    struct URLs: Decodable, Sendable {
        let full: URL?
        let small: URL?
        let regular: URL?
    }
    struct Links: Decodable, Sendable {
        let html: URL?
    }
    struct User: Decodable, Sendable {
        let name: String?
    }

    let id: String
    let width: Int?
    let height: Int?
    let description: String?
    let altDescription: String?
    let urls: URLs
    let links: Links
    let user: User?

    enum CodingKeys: String, CodingKey {
        case id, width, height, description, urls, links, user
        case altDescription = "alt_description"
    }

    func toDomain() -> Wallpaper {
        Wallpaper(
            id: "unsplash_\(id.sanitizedFileName)",
            source: .unsplash,
            title: altDescription?.nilIfEmpty ?? description?.nilIfEmpty ?? "Unsplash",
            description: description,
            imageURL: urls.full ?? urls.regular,
            thumbnailURL: urls.small,
            sourcePageURL: links.html,
            copyright: user?.name.map { "\($0) / Unsplash" } ?? "Unsplash",
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

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
