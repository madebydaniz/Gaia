import SwiftUI

struct SourceStatusView: View {
    let source: WallpaperSource
    let status: String

    var body: some View {
        HStack(spacing: 6) {
            Text(source.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
            Circle()
                .fill(indicatorColor)
                .frame(width: 6, height: 6)
            Text(LocalizedStringKey(status))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var indicatorColor: Color {
        switch status {
        case "status.rate_limited_cache":
            return .red
        case "status.offline_cache", "status.bundled_fallback":
            return .orange
        default:
            return .green
        }
    }
}
