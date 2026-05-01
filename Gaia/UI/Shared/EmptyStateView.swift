import SwiftUI

struct EmptyStateView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "photo.stack")
                .font(.system(size: 28, weight: .medium))
            Text("No wallpapers yet")
                .font(.headline)
            Button("Refresh") {
                action()
            }
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, minHeight: 180)
    }
}
