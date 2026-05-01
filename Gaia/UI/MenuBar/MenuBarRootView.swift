import SwiftUI

struct MenuBarRootView: View {
    @EnvironmentObject private var viewModel: WallpaperViewModel
    @EnvironmentObject private var preferences: PreferencesService
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if let current = viewModel.currentWallpaper {
                WallpaperPreviewCard(
                    wallpaper: current,
                    isCurrentDesktop: preferences.lastSelectedWallpaperId == current.id,
                    toggleFavorite: { Task { await viewModel.toggleFavorite() } },
                    openInfo: { viewModel.openSourcePage() }
                )
            } else {
                EmptyStateView {
                    Task { await viewModel.refresh() }
                }
            }

            if let error = viewModel.errorMessage, !error.isEmpty {
                ErrorStateView(message: error) {
                    Task { await viewModel.refresh() }
                }
            }

            if let update = viewModel.updateInfo, update.isUpdateAvailable {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("update.available.title")
                            .font(.caption.weight(.semibold))
                        Text(String(format: NSLocalizedString("update.available.subtitle", comment: ""), update.latestVersion))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("update.download") {
                        viewModel.openUpdateDownloadPage()
                    }
                    .buttonStyle(.link)
                }
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }

            navigationActions
            primaryAction
            if let successMessage = viewModel.successMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text(successMessage)
                        .lineLimit(1)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            quickActions
            footer
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.successMessage)
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .frame(width: 372)
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Gaia")
                    .font(.title3.bold())
                SourceStatusView(source: preferences.selectedSource, status: viewModel.statusText)
            }
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Refresh metadata")
            }
        }
    }

    private var navigationActions: some View {
        HStack(spacing: 8) {
            Button {
                Task { await viewModel.previous() }
            } label: {
                Label("Previous", systemImage: "chevron.left")
            }
            Button {
                Task { await viewModel.next() }
            } label: {
                Label("Next", systemImage: "chevron.right")
            }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .frame(maxWidth: .infinity)
    }

    private var primaryAction: some View {
        Button {
            Task { await viewModel.applyCurrentWallpaper() }
        } label: {
            Label("Change Now", systemImage: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .keyboardShortcut(.defaultAction)
        .disabled(viewModel.isLoading)
    }

    private var quickActions: some View {
        HStack(spacing: 8) {
            MenuBarActionButton(icon: "arrow.down.circle", title: "Save") {
                Task { await viewModel.downloadOriginal() }
            }
            MenuBarActionButton(icon: "folder", title: "Reveal") {
                viewModel.revealInFinder()
            }
            MenuBarActionButton(icon: "safari", title: "Source") {
                viewModel.openSourcePage()
            }
            MenuBarActionButton(icon: "link", title: "Copy") {
                viewModel.copyImageURL()
            }
        }
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var footer: some View {
        HStack {
            Button {
                dismiss()
                DispatchQueue.main.async {
                    openWindow(id: "settings")
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            Spacer()
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit Gaia", systemImage: "power")
            }
        }
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
