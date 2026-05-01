import Foundation

enum AppConfig {
    enum EnvironmentKey {
        static let nasaAPIKey = "GAIA_NASA_API_KEY"
        static let pexelsAPIKey = "GAIA_PEXELS_API_KEY"
        static let pixabayAPIKey = "GAIA_PIXABAY_API_KEY"
        static let unsplashAccessKey = "GAIA_UNSPLASH_ACCESS_KEY"
        static let googleEarthEndpoint = "GAIA_GOOGLE_EARTH_ENDPOINT"
    }

    enum Defaults {
        static let nasaAPIKey = "DEMO_KEY"
        static let bingMarket = "en-US"
        static let unsplashCategory = "nature"
        static let pexelsQuery = "nature"
        static let pixabayQuery = "landscape"
    }

    enum GitHub {
        static let owner = "madebydaniz"
        static let repo = "Gaia"
    }
}
