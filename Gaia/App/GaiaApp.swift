import SwiftUI

@main
struct GaiaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var preferences = PreferencesService()
    @StateObject private var viewModel: WallpaperViewModel
    private let scheduler: WallpaperScheduler
    private let updateScheduler: AppUpdateScheduler

    init() {
        let dependencies = AppDependencies.live()
        _viewModel = StateObject(wrappedValue: dependencies.viewModel)
        _preferences = StateObject(wrappedValue: dependencies.preferences)
        scheduler = dependencies.scheduler
        updateScheduler = dependencies.updateScheduler
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView()
                .environmentObject(viewModel)
                .environmentObject(preferences)
                .environment(\.locale, preferences.effectiveLocale)
                .task {
                    await viewModel.loadInitialData()
                    await viewModel.checkForUpdatesIfNeeded(onLaunch: true)
                    scheduler.start()
                    updateScheduler.start()
                }
        } label: {
            Image("MenuBarLogo")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)

        Window("Gaia Settings", id: "settings") {
            SettingsView()
                .environmentObject(viewModel)
                .environmentObject(preferences)
                .environment(\.locale, preferences.effectiveLocale)
        }
        .windowResizability(.contentSize)
    }
}

@MainActor
private struct AppDependencies {
    let preferences: PreferencesService
    let viewModel: WallpaperViewModel
    let scheduler: WallpaperScheduler
    let updateScheduler: AppUpdateScheduler

    static func live() -> AppDependencies {
        let preferences = PreferencesService()
        let fileStorage = FileStorage()
        let metadataStore = MetadataStore(fileStorage: fileStorage)
        let httpClient = URLSessionHTTPClient()
        let repositoryConfig = RepositoryConfiguration.live()
        let localRepository = LocalWallpaperRepository(
            fileStorage: fileStorage,
            metadataStore: metadataStore
        )
        let repositories: [WallpaperSource: WallpaperRepository] = [
            .bing: BingWallpaperRepository(httpClient: httpClient),
            .googleEarth: GoogleEarthWallpaperRepository(
                remoteEndpoint: repositoryConfig.googleEarthRemoteURL,
                httpClient: httpClient
            ),
            .nasaAPOD: NASAAPODWallpaperRepository(httpClient: httpClient, apiKey: repositoryConfig.nasaAPIKey),
            .nasaEPIC: NASAEPICWallpaperRepository(httpClient: httpClient, apiKey: repositoryConfig.nasaAPIKey),
            .pexels: PexelsWallpaperRepository(httpClient: httpClient, apiKey: repositoryConfig.pexelsAPIKey),
            .pixabay: PixabayWallpaperRepository(httpClient: httpClient, apiKey: repositoryConfig.pixabayAPIKey),
            .wikimediaCommons: WikimediaCommonsWallpaperRepository(httpClient: httpClient),
            .unsplash: UnsplashWallpaperRepository(
                httpClient: httpClient,
                accessKey: repositoryConfig.unsplashAPIKey,
                category: preferences.unsplashCategory
            ),
            .picsum: PicsumWallpaperRepository(httpClient: httpClient)
        ]
        let downloader = DefaultWallpaperImageDownloader(
            httpClient: httpClient,
            localRepository: localRepository,
            thumbnailGenerator: ThumbnailGenerator(fileStorage: fileStorage)
        )
        let service = WallpaperService(
            repositories: repositories,
            localRepository: localRepository,
            downloader: downloader,
            wallpaperSetter: MacOSWallpaperSetter(),
            preferences: preferences,
            fallbackProvider: BundledFallbackProvider()
        )
        let updateService = GitHubAppUpdateService(httpClient: httpClient)
        let updateNotifier = UpdateNotificationService()
        let viewModel = WallpaperViewModel(
            service: service,
            preferences: preferences,
            updateService: updateService,
            updateNotifier: updateNotifier
        )
        let scheduler = WallpaperScheduler(preferences: preferences) {
            await viewModel.changeNow()
        }
        let updateScheduler = AppUpdateScheduler(intervalHours: 6) {
            await viewModel.checkForUpdates()
        }
        return AppDependencies(
            preferences: preferences,
            viewModel: viewModel,
            scheduler: scheduler,
            updateScheduler: updateScheduler
        )
    }
}

@MainActor
private final class AppUpdateScheduler {
    private let checkAction: @MainActor () async -> Void
    private var task: Task<Void, Never>?
    private let intervalSeconds: UInt64

    init(intervalHours: Int, checkAction: @escaping @MainActor () async -> Void) {
        self.intervalSeconds = UInt64(max(1, intervalHours)) * 60 * 60
        self.checkAction = checkAction
    }

    func start() {
        task?.cancel()
        task = Task { [intervalSeconds, checkAction] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: intervalSeconds * 1_000_000_000)
                if Task.isCancelled { return }
                await checkAction()
            }
        }
    }
}
