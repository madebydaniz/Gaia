import Foundation

struct Endpoint: Sendable {
    let url: URL
    var timeout: TimeInterval = 20
    var headers: [String: String] = [:]
}
