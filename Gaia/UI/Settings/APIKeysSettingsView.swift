import SwiftUI

@MainActor
@Observable
final class APIKeysSettingsModel {
    private let storage: any ProviderKeyStorage
    private let validate: (APIKeyProvider, String) async -> APIKeyValidation
    private(set) var drafts: [APIKeyProvider: String] = [:]
    private(set) var saved: Set<APIKeyProvider> = []
    private(set) var messages: [APIKeyProvider: String] = [:]
    private(set) var isChecking = false

    convenience init() {
        self.init(storage: ProviderKeychain(), validate: APIKeyValidator().validate)
    }

    init(storage: any ProviderKeyStorage, validate: @escaping (APIKeyProvider, String) async -> APIKeyValidation) {
        self.storage = storage
        self.validate = validate
        for provider in APIKeyProvider.allCases {
            do {
                if let key = try storage.read(provider) {
                    drafts[provider] = key
                    saved.insert(provider)
                }
            } catch {
                messages[provider] = "apiKeys.keychainError"
            }
        }
    }

    var canValidate: Bool {
        !isChecking && drafts.values.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func edit(_ value: String, for provider: APIKeyProvider) {
        drafts[provider] = value
        messages[provider] = nil
    }

    func remove(_ provider: APIKeyProvider) {
        do {
            try storage.remove(provider)
            saved.remove(provider)
            edit("", for: provider)
        } catch {
            messages[provider] = "apiKeys.keychainError"
        }
    }

    func validateKeys() async {
        guard canValidate else { return }
        isChecking = true
        defer { isChecking = false }
        for provider in APIKeyProvider.allCases {
            let key = drafts[provider, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { continue }
            guard !Task.isCancelled else { return }
            messages[provider] = "apiKeys.checking"
            let result = await validate(provider, key)
            guard !Task.isCancelled else { return }
            if result == .accepted {
                do {
                    try storage.save(key, for: provider)
                    drafts[provider] = key
                    saved.insert(provider)
                } catch {
                    messages[provider] = "apiKeys.keychainError"
                    continue
                }
            }
            messages[provider] = result.rawValue
        }
    }
}

struct APIKeysSettingsView: View {
    @State private var model: APIKeysSettingsModel?
    @State private var checking: Task<Void, Never>?

    var body: some View {
        Form {
            if let model {
                Section {
                    ForEach(APIKeyProvider.allCases, id: \.self) { provider in
                        VStack(alignment: .leading) {
                            HStack {
                                SecureField(provider.rawValue, text: Binding(
                                    get: { model.drafts[provider, default: ""] },
                                    set: { model.edit($0, for: provider) }
                                ))
                                if model.saved.contains(provider) {
                                    Button(role: .destructive) { model.remove(provider) } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.borderless)
                                    .accessibilityLabel(Text("apiKeys.remove \(provider.rawValue)"))
                                    .help("apiKeys.remove")
                                }
                            }
                            if let message = model.messages[provider] {
                                Text(LocalizedStringKey(message)).font(.caption)
                            }
                        }
                        .disabled(model.isChecking)
                    }
                } header: {
                    Text("API Keys")
                } footer: {
                    Text("apiKeys.help")
                }
                Button("Validate Keys") {
                    checking = Task { await model.validateKeys() }
                }
                .disabled(!model.canValidate)
            }
        }
        .formStyle(.grouped)
        .onAppear { model = APIKeysSettingsModel() }
        .onDisappear { checking?.cancel() }
    }
}
