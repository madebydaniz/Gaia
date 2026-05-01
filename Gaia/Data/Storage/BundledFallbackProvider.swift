import Foundation

protocol WallpaperFallbackProvider {
    func loadFallback(source: WallpaperSource) async throws -> [Wallpaper]
}

final class BundledFallbackProvider: WallpaperFallbackProvider {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadFallback(source: WallpaperSource) async throws -> [Wallpaper] {
        switch source {
        case .favorites:
            return []
        case .bing:
            return try loadWallpapers(resource: "bing-fallback")
        case .googleEarth:
            let dtos = try loadDTOs(resource: "google-earth-fallback")
            return dtos.map { $0.toDomain() }
        case .mixed, .nasaAPOD, .nasaEPIC, .pexels, .pixabay, .wikimediaCommons, .unsplash, .picsum:
            return []
        }
    }

    private func loadWallpapers(resource: String) throws -> [Wallpaper] {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: url)
        return try decoder.decode([Wallpaper].self, from: data)
    }

    private func loadDTOs(resource: String) throws -> [GoogleEarthWallpaperDTO] {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            return []
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([GoogleEarthWallpaperDTO].self, from: data)
    }
}
