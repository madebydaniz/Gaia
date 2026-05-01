import Foundation

struct RepositoryConfiguration: Sendable {
    let nasaAPIKey: String
    let pexelsAPIKey: String?
    let pixabayAPIKey: String?
    let unsplashAPIKey: String?
    let googleEarthRemoteURL: URL?

    static func live(defaults: UserDefaults = .standard, environment: [String: String] = ProcessInfo.processInfo.environment) -> RepositoryConfiguration {
        let nasaKey = environment[AppConfig.EnvironmentKey.nasaAPIKey]
            ?? AppConfig.Defaults.nasaAPIKey

        return RepositoryConfiguration(
            nasaAPIKey: nasaKey,
            pexelsAPIKey: environment[AppConfig.EnvironmentKey.pexelsAPIKey],
            pixabayAPIKey: environment[AppConfig.EnvironmentKey.pixabayAPIKey],
            unsplashAPIKey: environment[AppConfig.EnvironmentKey.unsplashAccessKey],
            googleEarthRemoteURL: URL(string: environment[AppConfig.EnvironmentKey.googleEarthEndpoint] ?? defaults.string(forKey: "googleEarthEndpoint") ?? "")
        )
    }
}
