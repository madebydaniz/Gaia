import Foundation

struct AppUpdateInfo: Equatable, Sendable {
    let currentVersion: String
    let latestVersion: String
    let releaseURL: URL
    let isUpdateAvailable: Bool
}

protocol AppUpdateChecking: Sendable {
    func checkForUpdates(currentVersion: String) async throws -> AppUpdateInfo
}

struct GitHubAppUpdateService: AppUpdateChecking {
    private let httpClient: HTTPClient
    private let owner: String
    private let repo: String

    init(httpClient: HTTPClient, owner: String = AppConfig.GitHub.owner, repo: String = AppConfig.GitHub.repo) {
        self.httpClient = httpClient
        self.owner = owner
        self.repo = repo
    }

    func checkForUpdates(currentVersion: String) async throws -> AppUpdateInfo {
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest") else {
            throw NetworkError.invalidURL
        }
        let endpoint = Endpoint(
            url: url,
            timeout: 15,
            headers: [
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": "2022-11-28"
            ]
        )
        let dto = try await httpClient.decoded(GitHubReleaseDTO.self, from: endpoint, decoder: JSONDecoder())
        let latest = normalizedVersion(dto.tagName)
        let current = normalizedVersion(currentVersion)
        return AppUpdateInfo(
            currentVersion: current,
            latestVersion: latest,
            releaseURL: dto.htmlURL,
            isUpdateAvailable: compareVersions(lhs: latest, rhs: current) > 0
        )
    }

    private func normalizedVersion(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = trimmed.range(of: #"\d+(?:\.\d+){0,2}"#, options: .regularExpression) {
            return String(trimmed[range])
        }
        return trimmed.replacingOccurrences(of: "^v", with: "", options: .regularExpression)
    }

    private func compareVersions(lhs: String, rhs: String) -> Int {
        let l = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let r = rhs.split(separator: ".").map { Int($0) ?? 0 }
        let maxCount = max(l.count, r.count)
        for index in 0..<maxCount {
            let lv = index < l.count ? l[index] : 0
            let rv = index < r.count ? r[index] : 0
            if lv != rv { return lv > rv ? 1 : -1 }
        }
        return 0
    }
}

private struct GitHubReleaseDTO: Decodable, Sendable {
    let tagName: String
    let htmlURL: URL

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}
