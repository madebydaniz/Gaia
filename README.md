<div align="center">
  <img src=".github/assets/logo-app.png" alt="Gaia Logo" width="220">
  <h1>Gaia</h1>
</div>

Gaia is a modern macOS menu bar wallpaper manager built with SwiftUI.

It lets you browse wallpapers from multiple sources, preview quickly, apply in one click, and keep working with local cache even when network sources are temporarily unavailable.

## Why the Name "Gaia"?

The name **Gaia** is inspired by the concept of Earth and nature.

Because the app is focused on beautiful wallpapers from Earth, space, landscapes, and natural imagery, the name reflects that identity directly.

Reference:

- [Gaia (Wikipedia)](https://en.wikipedia.org/wiki/Gaia)

## Download

Download the latest build from:

- [Releases](https://github.com/madebydaniz/Gaia/releases)

## Features

- Native macOS menu bar app
- Modern compact panel UI with wallpaper preview
- Multiple wallpaper sources:
  - Bing
  - Google Earth
  - NASA APOD
  - NASA EPIC
  - Unsplash
  - Pexels
  - Pixabay
  - Wikimedia Commons
  - Picsum
  - Favorites source
  - Mixed source
- Async image download and local caching
- Offline fallback behavior from cache/bundled data
- Favorites and quick navigation (`Previous` / `Next`)
- Auto-change scheduling:
  - Manual
  - Hourly
  - Custom every N hours
  - Daily / Weekly
  - On login
  - On unlock
- Wallpaper apply target:
  - Main display
  - All displays
- Wallpaper fit mode:
  - Fill / Fit / Stretch / Tile / Center / Span
- Launch at login support
- Multi-language foundation (EN/DE/FA)

## Tech Stack

- Swift
- SwiftUI
- macOS AppKit integration where needed
- `async/await`
- Repository pattern + clean modular structure
- Local disk cache in Application Support
- `UserDefaults`-based preferences

## Provider API keys

Open **Settings → API Keys** to add, update, or remove a provider key in the installed app.

- **Pexels** and **Pixabay** use your API key. **Unsplash** uses your Access Key.
- **NASA APOD** and **NASA EPIC** share one key. They use NASA’s public demo key until you save your own.
- **Bing**, **Google Earth fallback data**, **Wikimedia Commons**, and **Picsum** work without a key.

Click **Validate Keys** to check each filled field. Gaia saves accepted keys in the macOS Keychain and uses them on the next wallpaper request. If a replacement fails validation, the previously saved key stays active. Use the trash button beside a provider to remove its saved key.

## Build & Run

1. Open `Gaia.xcodeproj`
2. Select `Gaia` scheme
3. Run on `My Mac`

Or with CLI:

```bash
xcodebuild -project Gaia.xcodeproj -scheme Gaia -destination 'platform=macOS' build
```

Create a release DMG locally:

```bash
./scripts/make-dmg.sh
```

Optional (recommended) for better DMG layout:

```bash
brew install create-dmg
```

## Data Source Licensing & Attribution

Wallpaper copyrights remain with their original owners/providers.

When using source APIs, you are responsible for complying with each provider’s terms, attribution requirements, and usage policies.

Gaia stores metadata and downloaded images locally only to provide app functionality (preview, offline cache, and wallpaper switching).

## Support

- Website: [madebydaniz.com](https://www.madebydaniz.com/)
- GitHub: [madebydaniz/Gaia](https://github.com/madebydaniz/Gaia)
- Contact: [contact@madebydaniz.com](mailto:contact@madebydaniz.com)

Support development:

- [GitHub Sponsors](https://github.com/sponsors/madebydaniz)
- [Buy Me a Coffee](https://buymeacoffee.com/madebydaniz)
