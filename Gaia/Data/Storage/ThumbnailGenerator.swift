import AppKit
import ImageIO
import UniformTypeIdentifiers

final class ThumbnailGenerator {
    private let fileStorage: FileStorage
    private let width: CGFloat

    init(fileStorage: FileStorage, width: CGFloat = 600) {
        self.fileStorage = fileStorage
        self.width = width
    }

    func generateThumbnail(from imageURL: URL, for wallpaper: Wallpaper) async throws -> URL {
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ImageCacheError.invalidImage
        }

        let scale = width / CGFloat(image.width)
        let size = NSSize(width: width, height: max(1, CGFloat(image.height) * scale))
        let nsImage = NSImage(cgImage: image, size: size)
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.82]) else {
            throw ImageCacheError.invalidImage
        }

        let url = fileStorage.thumbnailURL(for: wallpaper)
        try fileStorage.prepareDirectories()
        try jpegData.write(to: url, options: .atomic)
        return url
    }
}
