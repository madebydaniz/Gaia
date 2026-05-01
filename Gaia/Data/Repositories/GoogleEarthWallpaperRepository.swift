import Foundation

final class GoogleEarthWallpaperRepository: WallpaperRepository {
    let source: WallpaperSource = .googleEarth
    private let remoteEndpoint: URL?
    private let httpClient: HTTPClient?
    private let bundle: Bundle

    init(remoteEndpoint: URL? = nil, httpClient: HTTPClient? = nil, bundle: Bundle = .main) {
        self.remoteEndpoint = remoteEndpoint
        self.httpClient = httpClient
        self.bundle = bundle
    }

    func fetchLatest() async throws -> [Wallpaper] {
        if let remoteEndpoint, let httpClient {
            let decoder = JSONDecoder()
            let remote = try await httpClient.decoded([GoogleEarthWallpaperDTO].self, from: Endpoint(url: remoteEndpoint), decoder: decoder)
            return remote.map { $0.toDomain() }
        }
        return try bundledWallpapers()
    }

    func fetchRandom() async throws -> Wallpaper? {
        try await fetchLatest().randomElement()
    }

    func fetchById(_ id: String) async throws -> Wallpaper? {
        try await fetchLatest().first { $0.id == id }
    }

    private func bundledWallpapers() throws -> [Wallpaper] {
        guard let url = bundle.url(forResource: "google-earth-fallback", withExtension: "json") else {
            return []
        }
        let data = try Data(contentsOf: url)
        let dtos = try JSONDecoder().decode([GoogleEarthWallpaperDTO].self, from: data)
        return dtos.map { $0.toDomain() }
    }
}
