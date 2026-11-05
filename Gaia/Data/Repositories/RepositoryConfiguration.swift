import Foundation

struct RepositoryConfiguration: Sendable {
    let googleEarthRemoteURL: URL?

    static func live(defaults: UserDefaults = .standard, environment: [String: String] = ProcessInfo.processInfo.environment) -> RepositoryConfiguration {
        return RepositoryConfiguration(
            googleEarthRemoteURL: URL(string: environment[AppConfig.EnvironmentKey.googleEarthEndpoint] ?? defaults.string(forKey: "googleEarthEndpoint") ?? "")
        )
    }
}
