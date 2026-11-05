import Foundation

enum APIKeyValidation: String {
    case accepted = "apiKeys.valid"
    case rejected = "apiKeys.invalid"
    case rateLimited = "apiKeys.limit"
    case unavailable = "apiKeys.unavailable"
    case connectionFailed = "apiKeys.connection"
}

struct APIKeyValidator {
    private static let session = URLSession(configuration: .ephemeral, delegate: ValidationRedirectPolicy(), delegateQueue: nil)

    func validate(_ provider: APIKeyProvider, key: String) async -> APIKeyValidation {
        do {
            let (data, response) = try await Self.session.data(for: request(for: provider, key: key))
            guard let http = response as? HTTPURLResponse else { return .unavailable }
            return result(for: provider, response: http, data: data)
        } catch {
            return .connectionFailed
        }
    }

    func request(for provider: APIKeyProvider, key: String) -> URLRequest {
        var request: URLRequest
        switch provider {
        case .nasa:
            request = URLRequest(url: URL(string: "https://api.nasa.gov/planetary/apod")!)
            request.setValue(key, forHTTPHeaderField: "X-Api-Key")
        case .pexels:
            request = URLRequest(url: URL(string: "https://api.pexels.com/v1/curated?per_page=1")!)
            request.setValue(key, forHTTPHeaderField: "Authorization")
        case .pixabay:
            let url = URL(string: "https://pixabay.com/api/")!
            request = URLRequest(url: url.appending(queryItems: [
                URLQueryItem(name: "key", value: key), URLQueryItem(name: "per_page", value: "3")
            ]))
        case .unsplash:
            request = URLRequest(url: URL(string: "https://api.unsplash.com/photos?per_page=1")!)
            request.setValue("Client-ID \(key)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }

    func result(for provider: APIKeyProvider, response: HTTPURLResponse, data: Data) -> APIKeyValidation {
        switch response.statusCode {
        case 200..<300:
            guard let payload = try? JSONSerialization.jsonObject(with: data) else { return .unavailable }
            let object = payload as? [String: Any]
            switch provider {
            case .nasa: return object?["date"] is String ? .accepted : .unavailable
            case .pexels: return object?["photos"] is [Any] ? .accepted : .unavailable
            case .pixabay: return object?["hits"] is [Any] ? .accepted : .unavailable
            case .unsplash: return payload is [Any] ? .accepted : .unavailable
            }
        case 429: return .rateLimited
        case 401: return .rejected
        case 403:
            let body = String(decoding: data, as: UTF8.self).lowercased()
            if response.value(forHTTPHeaderField: "X-Ratelimit-Remaining") == "0" || body.contains("rate limit") {
                return .rateLimited
            }
            return .rejected
        case 400 where provider == .pixabay:
            return String(decoding: data, as: UTF8.self).contains("[key]") ? .rejected : .unavailable
        default: return .unavailable
        }
    }
}

private final class ValidationRedirectPolicy: NSObject, URLSessionTaskDelegate {
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask,
                                willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                                completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
