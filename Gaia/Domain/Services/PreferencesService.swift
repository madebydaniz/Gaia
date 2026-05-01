import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class PreferencesService: ObservableObject {
    enum Key {
        static let selectedSource = "selectedSource"
        static let changeInterval = "changeInterval"
        static let wallpaperQuality = "wallpaperQuality"
        static let applyTarget = "applyTarget"
        static let fitMode = "fitMode"
        static let launchAtLogin = "launchAtLogin"
        static let showDockIcon = "showDockIcon"
        static let saveDownloadedImages = "saveDownloadedImages"
        static let maxCacheSizeMB = "maxCacheSizeMB"
        static let deleteImagesOlderThanDays = "deleteImagesOlderThanDays"
        static let favoritesOnly = "favoritesOnly"
        static let lastSelectedWallpaperId = "lastSelectedWallpaperId"
        static let lastRefreshDate = "lastRefreshDate"
        static let lastChangeDate = "lastChangeDate"
        static let startMinimized = "startMinimized"
        static let checkOnLaunch = "checkOnLaunch"
        static let shuffleMode = "shuffleMode"
        static let bingMarket = "bingMarket"
        static let unsplashCategory = "unsplashCategory"
        static let autoChangeHours = "autoChangeHours"
        static let pexelsQuery = "pexelsQuery"
        static let pixabayQuery = "pixabayQuery"
        static let appLanguage = "appLanguage"
        static let lastUpdateCheckDate = "lastUpdateCheckDate"
        static let notifyOnUpdate = "notifyOnUpdate"
        static let lastNotifiedUpdateVersion = "lastNotifiedUpdateVersion"
    }

    private let defaults: UserDefaults

    @Published var selectedSource: WallpaperSource { didSet { set(selectedSource.rawValue, for: Key.selectedSource) } }
    @Published var changeInterval: WallpaperChangeInterval { didSet { set(changeInterval.rawValue, for: Key.changeInterval) } }
    @Published var wallpaperQuality: WallpaperQuality { didSet { set(wallpaperQuality.rawValue, for: Key.wallpaperQuality) } }
    @Published var applyTarget: WallpaperApplyTarget { didSet { set(applyTarget.rawValue, for: Key.applyTarget) } }
    @Published var fitMode: WallpaperFitMode { didSet { set(fitMode.rawValue, for: Key.fitMode) } }
    @Published var launchAtLogin: Bool { didSet { set(launchAtLogin, for: Key.launchAtLogin) } }
    @Published var showDockIcon: Bool { didSet { set(showDockIcon, for: Key.showDockIcon); applyDockPolicy() } }
    @Published var startMinimized: Bool { didSet { set(startMinimized, for: Key.startMinimized) } }
    @Published var checkOnLaunch: Bool { didSet { set(checkOnLaunch, for: Key.checkOnLaunch) } }
    @Published var saveDownloadedImages: Bool { didSet { set(saveDownloadedImages, for: Key.saveDownloadedImages) } }
    @Published var maxCacheSizeMB: Int { didSet { set(maxCacheSizeMB, for: Key.maxCacheSizeMB) } }
    @Published var deleteImagesOlderThanDays: Int { didSet { set(deleteImagesOlderThanDays, for: Key.deleteImagesOlderThanDays) } }
    @Published var favoritesOnly: Bool { didSet { set(favoritesOnly, for: Key.favoritesOnly) } }
    @Published var shuffleMode: WallpaperShuffleMode { didSet { set(shuffleMode.rawValue, for: Key.shuffleMode) } }
    @Published var bingMarket: BingMarket { didSet { set(bingMarket.rawValue, for: Key.bingMarket) } }
    @Published var unsplashCategory: String { didSet { set(unsplashCategory, for: Key.unsplashCategory) } }
    @Published var autoChangeHours: Int { didSet { set(autoChangeHours, for: Key.autoChangeHours) } }
    @Published var pexelsQuery: String { didSet { set(pexelsQuery, for: Key.pexelsQuery) } }
    @Published var pixabayQuery: String { didSet { set(pixabayQuery, for: Key.pixabayQuery) } }
    @Published var appLanguage: AppLanguage { didSet { set(appLanguage.rawValue, for: Key.appLanguage) } }
    @Published var notifyOnUpdate: Bool { didSet { set(notifyOnUpdate, for: Key.notifyOnUpdate) } }

    var effectiveLocale: Locale {
        appLanguage.locale ?? .autoupdatingCurrent
    }

    var lastSelectedWallpaperId: String? {
        get { defaults.string(forKey: Key.lastSelectedWallpaperId) }
        set { defaults.set(newValue, forKey: Key.lastSelectedWallpaperId) }
    }

    var lastRefreshDate: Date? {
        get { defaults.object(forKey: Key.lastRefreshDate) as? Date }
        set { defaults.set(newValue, forKey: Key.lastRefreshDate) }
    }

    var lastChangeDate: Date? {
        get { defaults.object(forKey: Key.lastChangeDate) as? Date }
        set { defaults.set(newValue, forKey: Key.lastChangeDate) }
    }

    var lastUpdateCheckDate: Date? {
        get { defaults.object(forKey: Key.lastUpdateCheckDate) as? Date }
        set { defaults.set(newValue, forKey: Key.lastUpdateCheckDate) }
    }

    var lastNotifiedUpdateVersion: String? {
        get { defaults.string(forKey: Key.lastNotifiedUpdateVersion) }
        set { defaults.set(newValue, forKey: Key.lastNotifiedUpdateVersion) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selectedSource = Self.enumValue(defaults, key: Key.selectedSource, fallback: .bing)
        let storedInterval: WallpaperChangeInterval = Self.enumValue(defaults, key: Key.changeInterval, fallback: .manual)
        changeInterval = storedInterval == .everyThreeHours ? .customHours : storedInterval
        wallpaperQuality = Self.enumValue(defaults, key: Key.wallpaperQuality, fallback: .hd)
        applyTarget = Self.enumValue(defaults, key: Key.applyTarget, fallback: .mainDisplay)
        fitMode = Self.enumValue(defaults, key: Key.fitMode, fallback: .fill)
        launchAtLogin = defaults.object(forKey: Key.launchAtLogin) as? Bool ?? false
        showDockIcon = defaults.object(forKey: Key.showDockIcon) as? Bool ?? false
        startMinimized = defaults.object(forKey: Key.startMinimized) as? Bool ?? true
        checkOnLaunch = defaults.object(forKey: Key.checkOnLaunch) as? Bool ?? true
        saveDownloadedImages = defaults.object(forKey: Key.saveDownloadedImages) as? Bool ?? true
        maxCacheSizeMB = defaults.object(forKey: Key.maxCacheSizeMB) as? Int ?? 512
        deleteImagesOlderThanDays = defaults.object(forKey: Key.deleteImagesOlderThanDays) as? Int ?? 60
        favoritesOnly = defaults.object(forKey: Key.favoritesOnly) as? Bool ?? false
        shuffleMode = Self.enumValue(defaults, key: Key.shuffleMode, fallback: .latestFirst)
        bingMarket = Self.enumValue(defaults, key: Key.bingMarket, fallback: .enUS)
        unsplashCategory = defaults.string(forKey: Key.unsplashCategory) ?? AppConfig.Defaults.unsplashCategory
        let defaultHours = storedInterval == .everyThreeHours ? 3 : 3
        autoChangeHours = max(1, defaults.object(forKey: Key.autoChangeHours) as? Int ?? defaultHours)
        pexelsQuery = defaults.string(forKey: Key.pexelsQuery) ?? AppConfig.Defaults.pexelsQuery
        pixabayQuery = defaults.string(forKey: Key.pixabayQuery) ?? AppConfig.Defaults.pixabayQuery
        appLanguage = Self.enumValue(defaults, key: Key.appLanguage, fallback: .system)
        notifyOnUpdate = defaults.object(forKey: Key.notifyOnUpdate) as? Bool ?? true
        applyDockPolicy()
    }

    private func set(_ value: Any?, for key: String) {
        defaults.set(value, forKey: key)
    }

    private static func enumValue<T: RawRepresentable>(_ defaults: UserDefaults, key: String, fallback: T) -> T where T.RawValue == String {
        guard let raw = defaults.string(forKey: key), let value = T(rawValue: raw) else {
            return fallback
        }
        return value
    }

    private func applyDockPolicy() {
        let policy: NSApplication.ActivationPolicy = showDockIcon ? .regular : .accessory
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(policy)
        }
    }
}
