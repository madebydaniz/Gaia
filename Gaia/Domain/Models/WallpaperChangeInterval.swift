import Foundation

enum WallpaperChangeInterval: String, Codable, CaseIterable, Identifiable, Sendable {
    case manual
    case hourly
    case customHours
    case everyThreeHours
    case everySixHours
    case daily
    case weekly
    case onLogin
    case onUnlock

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .manual: String(localized: "interval.manual")
        case .hourly: String(localized: "interval.hourly")
        case .customHours: String(localized: "interval.custom_hours")
        case .everyThreeHours: String(localized: "interval.every_three_hours")
        case .everySixHours: String(localized: "interval.every_six_hours")
        case .daily: String(localized: "interval.daily")
        case .weekly: String(localized: "interval.weekly")
        case .onLogin: String(localized: "interval.on_login")
        case .onUnlock: String(localized: "interval.on_unlock")
        }
    }

    var timeInterval: TimeInterval? {
        switch self {
        case .manual: nil
        case .hourly: 60 * 60
        case .customHours: nil
        case .everyThreeHours: 3 * 60 * 60
        case .everySixHours: 6 * 60 * 60
        case .daily: 24 * 60 * 60
        case .weekly: 7 * 24 * 60 * 60
        case .onLogin, .onUnlock: nil
        }
    }
}
