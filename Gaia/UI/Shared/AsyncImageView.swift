import SwiftUI

struct AsyncImageView: View {
    let remoteURL: URL?
    let localPath: String?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let localPath, let image = NSImage(contentsOfFile: localPath) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else if let remoteURL {
                    AsyncImage(url: remoteURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .clipped()
                        case .failure:
                            placeholder
                        case .empty:
                            loadingPlaceholder
                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
    }

    private var placeholder: some View {
        ZStack {
            Rectangle().fill(.quaternary)
            Image(systemName: "photo")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var loadingPlaceholder: some View {
        ZStack {
            Rectangle().fill(.quaternary)
            ProgressView()
                .controlSize(.small)
        }
    }
}
