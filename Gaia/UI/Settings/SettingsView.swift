import SwiftUI

struct SettingsView: View {
    @State private var selection: SettingsSection? = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selection) { section in
                Label(section.titleKey, systemImage: section.iconName)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            Group {
                switch selection ?? .general {
                case .general:
                    GeneralSettingsView()
                case .wallpaper:
                    WallpaperSettingsView()
                case .cache:
                    CacheSettingsView()
                case .about:
                    AboutSettingsView()
                case .support:
                    SupportSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationTitle("Settings")
        .frame(width: 780, height: 520)
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case wallpaper
    case cache
    case about
    case support

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .general: return "General"
        case .wallpaper: return "Wallpaper"
        case .cache: return "Cache"
        case .about: return "About"
        case .support: return "Support"
        }
    }

    var iconName: String {
        switch self {
        case .general: return "gearshape"
        case .wallpaper: return "photo"
        case .cache: return "externaldrive"
        case .about: return "info.circle"
        case .support: return "lifepreserver"
        }
    }
}
