import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case english = "en"
    case german = "de"

    var id: String { rawValue }

    var locale: Locale? {
        switch self {
        case .system:
            return nil
        default:
            return Locale(identifier: rawValue)
        }
    }

    var displayName: String {
        switch self {
        case .system: return String(localized: "language.system")
        case .english: return String(localized: "language.english")
        case .german: return String(localized: "language.german")
        }
    }
}
