import Foundation

protocol BingMarketConfigurable {
    func setMarket(_ market: String)
}

final class BingWallpaperRepository: WallpaperRepository {
    let source: WallpaperSource = .bing
    private let httpClient: HTTPClient
    private var market: String

    init(httpClient: HTTPClient, market: String = AppConfig.Defaults.bingMarket) {
        self.httpClient = httpClient
        self.market = market
    }

    func fetchLatest() async throws -> [Wallpaper] {
        guard let url = URL(string: "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=8&mkt=\(market)") else {
            throw NetworkError.invalidURL
        }
        let response = try await httpClient.decoded(BingWallpaperResponseDTO.self, from: Endpoint(url: url), decoder: JSONDecoder())
        return response.images.map { $0.toDomain() }
    }

    func fetchRandom() async throws -> Wallpaper? {
        try await fetchLatest().randomElement()
    }

    func fetchById(_ id: String) async throws -> Wallpaper? {
        try await fetchLatest().first { $0.id == id }
    }
}

extension BingWallpaperRepository: BingMarketConfigurable {
    func setMarket(_ market: String) {
        self.market = market
    }
}
