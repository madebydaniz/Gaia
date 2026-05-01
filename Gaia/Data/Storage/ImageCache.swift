import Foundation

enum ImageCacheError: Error, LocalizedError {
    case missingRemoteURL
    case invalidImage
    case unsupportedMimeType(String?)

    var errorDescription: String? {
        switch self {
        case .missingRemoteURL: "Wallpaper has no image URL."
        case .invalidImage: "Downloaded image is invalid."
        case .unsupportedMimeType(let type): "Unsupported image type \(type ?? "unknown")."
        }
    }
}
