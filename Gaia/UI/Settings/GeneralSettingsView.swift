import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject private var preferences: PreferencesService
    @State private var launchError: String?
    private let launchAtLoginService = LaunchAtLoginService()

    var body: some View {
        Form {
            GroupBox("Startup") {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Launch at login", isOn: launchBinding)
                    Toggle("Start minimized/menu bar only", isOn: $preferences.startMinimized)
                    Toggle("Check for new wallpapers on launch", isOn: $preferences.checkOnLaunch)
                    Toggle("Notify me about app updates", isOn: $preferences.notifyOnUpdate)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }

            GroupBox("Appearance") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("App language", selection: $preferences.appLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    Toggle("Show Dock icon", isOn: $preferences.showDockIcon)
                    Text("Changing Dock icon visibility may require restarting Gaia.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Language changes apply immediately for localized UI strings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }

            if let launchError {
                Text(launchError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }

    private var launchBinding: Binding<Bool> {
        Binding(
            get: { preferences.launchAtLogin },
            set: { newValue in
                do {
                    try launchAtLoginService.setEnabled(newValue)
                    preferences.launchAtLogin = newValue
                    launchError = nil
                } catch {
                    launchError = error.localizedDescription
                }
            }
        )
    }
}
