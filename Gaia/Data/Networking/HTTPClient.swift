import Foundation

protocol HTTPClient {
    nonisolated func data(from endpoint: Endpoint) async throws -> (Data, HTTPURLResponse)
    nonisolated func decoded<T: Decodable>(_ type: T.Type, from endpoint: Endpoint, decoder: JSONDecoder) async throws -> T
}

final class URLSessionHTTPClient: HTTPClient {
    nonisolated func data(from endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: endpoint.url)
        request.timeoutInterval = endpoint.timeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        for (name, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: name)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpStatus(httpResponse.statusCode)
            }
            return (data, httpResponse)
        } catch let error as NetworkError {
            throw error
        } catch {
            if (error as NSError).domain == NSURLErrorDomain {
                throw NetworkError.offline
            }
            throw NetworkError.unknown(error.localizedDescription)
        }
    }

    nonisolated func decoded<T: Decodable>(_ type: T.Type, from endpoint: Endpoint, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        let (data, _) = try await data(from: endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }
}
