import Foundation

enum WallpaperShuffleMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case latestFirst
    case random
    case favoritesOnly
    case mixedSources

    var id: String { rawValue }

    static let versionOneModes: [WallpaperShuffleMode] = allCases

    var displayName: String {
        switch self {
        case .latestFirst: String(localized: "shuffle.latest_first")
        case .random: String(localized: "shuffle.random")
        case .favoritesOnly: String(localized: "shuffle.favorites_only")
        case .mixedSources: String(localized: "shuffle.mixed_sources")
        }
    }
}
