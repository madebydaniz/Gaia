import Foundation

enum BingMarket: String, Codable, CaseIterable, Identifiable, Sendable {
    case enUS = "en-US"
    case deDE = "de-DE"
    case faIR = "fa-IR"
    case frFR = "fr-FR"
    case esES = "es-ES"
    case itIT = "it-IT"
    case ptBR = "pt-BR"
    case jaJP = "ja-JP"
    case koKR = "ko-KR"
    case zhCN = "zh-CN"
    case zhTW = "zh-TW"
    case ruRU = "ru-RU"
    case trTR = "tr-TR"
    case arSA = "ar-SA"
    case hiIN = "hi-IN"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .enUS: "English (US)"
        case .deDE: "Deutsch (DE)"
        case .faIR: "Farsi (IR)"
        case .frFR: "Francais (FR)"
        case .esES: "Espanol (ES)"
        case .itIT: "Italiano (IT)"
        case .ptBR: "Portugues (BR)"
        case .jaJP: "Japanese (JP)"
        case .koKR: "Korean (KR)"
        case .zhCN: "Chinese Simplified"
        case .zhTW: "Chinese Traditional"
        case .ruRU: "Russian (RU)"
        case .trTR: "Turkish (TR)"
        case .arSA: "Arabic (SA)"
        case .hiIN: "Hindi (IN)"
        }
    }
}
