import SwiftUI

struct WallpaperPreviewCard: View {
    let wallpaper: Wallpaper
    let isCurrentDesktop: Bool
    let toggleFavorite: () -> Void
    let openInfo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                AsyncImageView(remoteURL: wallpaper.thumbnailURL ?? wallpaper.imageURL, localPath: wallpaper.localThumbnailPath)
                    .frame(maxWidth: .infinity)
                    .frame(height: 198)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .topLeading) {
                        Text(wallpaper.source.displayName)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(8)
                    }
                Button(action: toggleFavorite) {
                    Image(systemName: wallpaper.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(wallpaper.isFavorite ? .red : .primary)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(8)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(8)
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(wallpaper.displayTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    if let copyright = wallpaper.copyright {
                        Text(copyright)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text(" ")
                            .font(.caption)
                            .lineLimit(2)
                    }
                    HStack(spacing: 8) {
                        if isCurrentDesktop {
                            Label("Current Desktop", systemImage: "checkmark.circle.fill")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.green)
                                .lineLimit(1)
                        }
                    }
                    .frame(height: 14, alignment: .leading)
                }
                .frame(minHeight: 52, alignment: .topLeading)
                Spacer()
                Button(action: openInfo) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(wallpaper.sourcePageURL == nil)
            }
        }
        .padding(10)
        .frame(height: 286)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
