import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: generate-dmg-background.swift <logo-path> <output-path>\n", stderr)
    exit(1)
}

let logoPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

let canvasSize = NSSize(width: 860, height: 560)
let image = NSImage(size: canvasSize)

image.lockFocus()

NSColor(calibratedWhite: 0.93, alpha: 1.0).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()

if let logo = NSImage(contentsOfFile: logoPath) {
    let maxLogoWidth: CGFloat = 136
    let maxLogoHeight: CGFloat = 136
    let ratio = min(maxLogoWidth / logo.size.width, maxLogoHeight / logo.size.height, 1)
    let drawSize = NSSize(width: logo.size.width * ratio, height: logo.size.height * ratio)
    let rect = NSRect(
        x: (canvasSize.width - drawSize.width) / 2,
        y: canvasSize.height - drawSize.height - 4,
        width: drawSize.width,
        height: drawSize.height
    )
    logo.draw(in: rect)
}

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let textAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 22, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.35, alpha: 1.0),
    .paragraphStyle: paragraph
]
let text = "Drag Gaia to Applications"
text.draw(
    in: NSRect(x: 0, y: 92, width: canvasSize.width, height: 34),
    withAttributes: textAttributes
)

image.unlockFocus()

guard
    let tiffData = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiffData),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Failed to render PNG.\n", stderr)
    exit(1)
}

do {
    try pngData.write(to: URL(fileURLWithPath: outputPath))
} catch {
    fputs("Failed to write output: \(error)\n", stderr)
    exit(1)
}
