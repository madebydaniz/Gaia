import SwiftUI

struct SupportSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("support.section.developer") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("support.developer.name")
                    Link("https://www.madebydaniz.com/", destination: URL(string: "https://www.madebydaniz.com")!)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }

            GroupBox("support.section.contact") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("support.contact.description")
                        .foregroundStyle(.secondary)
                    Link("contact@madebydaniz.com", destination: URL(string: "mailto:contact@madebydaniz.com")!)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }

            GroupBox("support.section.support_gaia") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("support.donate.description")
                        .foregroundStyle(.secondary)
                    Link(String(localized: "support.link.github_sponsors"), destination: URL(string: "https://github.com/sponsors/madebydaniz")!)
                    Link(String(localized: "support.link.buy_me_a_coffee"), destination: URL(string: "https://buymeacoffee.com/madebydaniz")!)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
