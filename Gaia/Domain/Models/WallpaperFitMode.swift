import Foundation

enum WallpaperFitMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case fill
    case fit
    case stretch
    case tile
    case center
    case span

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fill: String(localized: "fit.fill")
        case .fit: String(localized: "fit.fit")
        case .stretch: String(localized: "fit.stretch")
        case .tile: String(localized: "fit.tile")
        case .center: String(localized: "fit.center")
        case .span: String(localized: "fit.span")
        }
    }
}
