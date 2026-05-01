import AppKit

struct ScreenProvider {
    var main: NSScreen? { NSScreen.main }
    var all: [NSScreen] { NSScreen.screens }
}
