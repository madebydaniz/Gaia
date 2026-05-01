import SwiftUI

struct CacheSettingsView: View {
    @EnvironmentObject private var preferences: PreferencesService
    @EnvironmentObject private var viewModel: WallpaperViewModel

    var body: some View {
        Form {
            GroupBox("Storage") {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Save downloaded images", isOn: $preferences.saveDownloadedImages)
                    Stepper("Maximum cache size: \(preferences.maxCacheSizeMB) MB", value: $preferences.maxCacheSizeMB, in: 100...4096, step: 50)
                    Stepper("Delete images older than \(preferences.deleteImagesOlderThanDays) days", value: $preferences.deleteImagesOlderThanDays, in: 1...365)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }

            GroupBox("Actions") {
                HStack {
                    Button("Clear thumbnails") {
                        Task { await viewModel.clearThumbnails() }
                    }
                    Button("Clear downloads") {
                        Task { await viewModel.clearDownloadedImages() }
                    }
                    Spacer()
                    Button("Show folder") {
                        let url = FileStorage().rootURL
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
                .padding(4)
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }
}
