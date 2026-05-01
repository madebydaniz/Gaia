import Foundation

enum WallpaperApplyTarget: String, Codable, CaseIterable, Identifiable, Sendable {
    case mainDisplay
    case allDisplays

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mainDisplay: String(localized: "apply.main_display")
        case .allDisplays: String(localized: "apply.all_displays")
        }
    }
}
