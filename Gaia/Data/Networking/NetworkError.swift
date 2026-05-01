import Foundation

enum NetworkError: Error, LocalizedError, Equatable, Sendable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
    case offline
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Invalid server response."
        case .httpStatus(let status):
            return status == 429
                ? "Rate limit reached (429). Using cached wallpapers for now."
                : "Unexpected HTTP status \(status)."
        case .decodingFailed:
            return "Could not decode server response."
        case .offline:
            return "Network appears to be offline."
        case .unknown(let message):
            return message
        }
    }
}
