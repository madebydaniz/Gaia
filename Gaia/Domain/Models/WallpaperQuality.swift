import Foundation

enum WallpaperQuality: String, Codable, CaseIterable, Identifiable, Sendable {
    case thumbnail
    case hd
    case uhd

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .thumbnail: String(localized: "quality.thumbnail")
        case .hd: String(localized: "quality.hd")
        case .uhd: String(localized: "quality.uhd")
        }
    }
}
