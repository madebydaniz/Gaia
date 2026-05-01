import AppKit
import Foundation

enum WallpaperSetError: Error, LocalizedError {
    case fileNotFound
    case noScreenAvailable

    var errorDescription: String? {
        switch self {
        case .fileNotFound: "Wallpaper file was not found."
        case .noScreenAvailable: "No display is available."
        }
    }
}

final class MacOSWallpaperSetter: WallpaperSetter {
    func setWallpaper(_ fileURL: URL, target: WallpaperApplyTarget, fitMode: WallpaperFitMode) async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw WallpaperSetError.fileNotFound
        }

        let screens: [NSScreen]
        switch target {
        case .mainDisplay:
            screens = NSScreen.main.map { [$0] } ?? []
        case .allDisplays:
            screens = NSScreen.screens
        }

        guard !screens.isEmpty else {
            throw WallpaperSetError.noScreenAvailable
        }

        let options = desktopOptions(for: fitMode)
        for screen in screens {
            try NSWorkspace.shared.setDesktopImageURL(fileURL, for: screen, options: options)
        }
    }

    private func desktopOptions(for fitMode: WallpaperFitMode) -> [NSWorkspace.DesktopImageOptionKey: Any] {
        switch fitMode {
        case .fill:
            return [
                .imageScaling: NSNumber(value: NSImageScaling.scaleAxesIndependently.rawValue),
                .allowClipping: true
            ]
        case .fit:
            return [
                .imageScaling: NSNumber(value: NSImageScaling.scaleProportionallyUpOrDown.rawValue),
                .allowClipping: false
            ]
        case .stretch:
            return [
                .imageScaling: NSNumber(value: NSImageScaling.scaleAxesIndependently.rawValue),
                .allowClipping: false
            ]
        case .tile:
            return [
                .imageScaling: NSNumber(value: NSImageScaling.scaleNone.rawValue),
                .allowClipping: false
            ]
        case .center:
            return [
                .imageScaling: NSNumber(value: NSImageScaling.scaleNone.rawValue),
                .allowClipping: true
            ]
        case .span:
            return [
                .imageScaling: NSNumber(value: NSImageScaling.scaleProportionallyUpOrDown.rawValue),
                .allowClipping: true
            ]
        }
    }
}
