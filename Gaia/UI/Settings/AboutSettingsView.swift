import SwiftUI

struct AboutSettingsView: View {
    @EnvironmentObject private var viewModel: WallpaperViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading) {
                    Text("Gaia")
                        .font(.title2.bold())
                    Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0")")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            GroupBox("about.section.about_gaia") {
                Text("about.text.about_gaia")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
            }

            GroupBox("about.section.data_sources") {
                Text("about.text.data_sources")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
            }

            GroupBox("about.section.license") {
                Text("about.text.license")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
            }

            GroupBox("about.section.updates") {
                VStack(alignment: .leading, spacing: 8) {
                    if let update = viewModel.updateInfo {
                        Text(String(format: NSLocalizedString("about.update.current_latest", comment: ""), update.currentVersion, update.latestVersion))
                            .foregroundStyle(.secondary)
                        if update.isUpdateAvailable {
                            Button("update.download") {
                                viewModel.openUpdateDownloadPage()
                            }
                        } else {
                            Text("about.update.up_to_date")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    } else {
                        Text("about.update.not_checked")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        Task { await viewModel.checkForUpdates() }
                    } label: {
                        if viewModel.isCheckingForUpdate {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("about.update.check_now")
                        }
                    }
                    .disabled(viewModel.isCheckingForUpdate)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }

            HStack(spacing: 14) {
                Link(String(localized: "about.link.website"), destination: URL(string: "https://www.madebydaniz.com/")!)
                Link(String(localized: "about.link.github"), destination: URL(string: "https://github.com/madebydaniz/Gaia")!)
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
