import Foundation

enum WallpaperSource: String, Codable, CaseIterable, Identifiable, Sendable {
    case favorites
    case bing
    case googleEarth
    case mixed
    case nasaAPOD
    case nasaEPIC
    case pexels
    case pixabay
    case wikimediaCommons
    case unsplash
    case picsum

    var id: String { rawValue }

    static let versionOneSources: [WallpaperSource] = allCases
    static let cacheableSources: [WallpaperSource] = allCases.filter { $0 != .mixed && $0 != .favorites }

    var isAvailableInVersionOne: Bool {
        Self.versionOneSources.contains(self)
    }

    var displayName: String {
        switch self {
        case .favorites: String(localized: "source.favorites")
        case .bing: String(localized: "source.bing")
        case .googleEarth: String(localized: "source.google_earth")
        case .mixed: String(localized: "source.mixed")
        case .nasaAPOD: String(localized: "source.nasa_apod")
        case .nasaEPIC: String(localized: "source.nasa_epic")
        case .pexels: String(localized: "source.pexels")
        case .pixabay: String(localized: "source.pixabay")
        case .wikimediaCommons: String(localized: "source.wikimedia_commons")
        case .unsplash: String(localized: "source.unsplash")
        case .picsum: String(localized: "source.picsum")
        }
    }

    var storageName: String {
        switch self {
        case .favorites: "favorites"
        case .bing: "bing"
        case .googleEarth: "google-earth"
        case .mixed: "mixed"
        case .nasaAPOD: "nasa-apod"
        case .nasaEPIC: "nasa-epic"
        case .pexels: "pexels"
        case .pixabay: "pixabay"
        case .wikimediaCommons: "wikimedia-commons"
        case .unsplash: "unsplash"
        case .picsum: "picsum"
        }
    }
}
