import SwiftUI

struct WallpaperSettingsView: View {
    @EnvironmentObject private var preferences: PreferencesService
    @EnvironmentObject private var viewModel: WallpaperViewModel
    private let unsplashCategories = ["nature", "landscape", "city", "minimal", "abstract", "architecture", "mountains", "ocean", "space"]
    private let behaviorOptions = WallpaperChangeInterval.allCases.filter { $0 != .everyThreeHours && $0 != .everySixHours }

    var body: some View {
        Form {
            GroupBox("Source") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Source", selection: $preferences.selectedSource) {
                        ForEach(WallpaperSource.allCases) { source in
                            Text(source.displayName).tag(source)
                        }
                    }
                    if preferences.selectedSource == .bing {
                        Picker("Bing market", selection: $preferences.bingMarket) {
                            ForEach(BingMarket.allCases) { market in
                                Text(market.displayName).tag(market)
                            }
                        }
                    }
                    if preferences.selectedSource == .unsplash {
                        Picker("Unsplash category", selection: $preferences.unsplashCategory) {
                            ForEach(unsplashCategories, id: \.self) { category in
                                Text(localizedCategory(category)).tag(category)
                            }
                        }
                    } else if preferences.selectedSource == .pexels {
                        TextField("Pexels query", text: $preferences.pexelsQuery)
                            .textFieldStyle(.roundedBorder)
                    } else if preferences.selectedSource == .pixabay {
                        TextField("Pixabay query", text: $preferences.pixabayQuery)
                            .textFieldStyle(.roundedBorder)
                    }
                    Button("Refresh selected source") {
                        Task { await viewModel.refresh() }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }

            GroupBox("Wallpaper") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Apply to", selection: $preferences.applyTarget) {
                        ForEach(WallpaperApplyTarget.allCases) { target in
                            Text(target.displayName).tag(target)
                        }
                    }
                    Picker("Image quality", selection: $preferences.wallpaperQuality) {
                        ForEach(WallpaperQuality.allCases) { quality in
                            Text(quality.displayName).tag(quality)
                        }
                    }
                    Picker("Wallpaper fit", selection: $preferences.fitMode) {
                        ForEach(WallpaperFitMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }

            GroupBox("Change") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Behavior", selection: $preferences.changeInterval) {
                        ForEach(behaviorOptions) { interval in
                            if interval == .customHours {
                                Text(customHoursLabel).tag(interval)
                            } else {
                                Text(interval.displayName).tag(interval)
                            }
                        }
                    }
                    if preferences.changeInterval == .customHours {
                        Stepper(value: $preferences.autoChangeHours, in: 1...168) {
                            Text(customHoursLabel)
                        }
                    }
                    Picker("Order", selection: $preferences.shuffleMode) {
                        ForEach(WallpaperShuffleMode.versionOneModes) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    Toggle("Favorites only", isOn: $preferences.favoritesOnly)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .onChange(of: preferences.selectedSource) {
            Task { await viewModel.refresh() }
        }
        .onChange(of: preferences.bingMarket) {
            if preferences.selectedSource == .bing || preferences.selectedSource == .mixed {
                Task { await viewModel.refresh() }
            }
        }
        .onChange(of: preferences.unsplashCategory) {
            if preferences.selectedSource == .unsplash || preferences.selectedSource == .mixed {
                Task { await viewModel.refresh() }
            }
        }
        .onSubmit {
            if [.pexels, .pixabay].contains(preferences.selectedSource) {
                Task { await viewModel.refresh() }
            }
        }
    }

    private func localizedCategory(_ category: String) -> String {
        String(localized: "unsplash.category.\(category)")
    }

    private var customHoursLabel: String {
        let format = NSLocalizedString("interval.custom_hours_format", comment: "")
        return String(format: format, preferences.autoChangeHours)
    }
}
