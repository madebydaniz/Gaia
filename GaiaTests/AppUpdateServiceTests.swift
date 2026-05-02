import Foundation
import Testing
@testable import Gaia

struct AppUpdateServiceTests {
    @Test
    func detectsUpdateFromComponentPrefixedTag() async throws {
        let payload = """
        {
          "tag_name": "gaia-v0.1.1",
          "html_url": "https://github.com/madebydaniz/Gaia/releases/tag/gaia-v0.1.1"
        }
        """
        let service = GitHubAppUpdateService(httpClient: MockHTTPClient(data: payload.data(using: .utf8)!))

        let info = try await service.checkForUpdates(currentVersion: "0.1.0")

        #expect(info.latestVersion == "0.1.1")
        #expect(info.currentVersion == "0.1.0")
        #expect(info.isUpdateAvailable)
    }

    @Test
    func noUpdateWhenVersionsMatch() async throws {
        let payload = """
        {
          "tag_name": "v1.2.3",
          "html_url": "https://github.com/madebydaniz/Gaia/releases/tag/v1.2.3"
        }
        """
        let service = GitHubAppUpdateService(httpClient: MockHTTPClient(data: payload.data(using: .utf8)!))

        let info = try await service.checkForUpdates(currentVersion: "1.2.3")

        #expect(info.latestVersion == "1.2.3")
        #expect(!info.isUpdateAvailable)
    }
}

private struct MockHTTPClient: HTTPClient {
    let data: Data

    func data(from endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(
            url: endpoint.url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [:]
        )!
        return (data, response)
    }
}
