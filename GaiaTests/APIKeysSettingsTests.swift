import Foundation
import Testing
@testable import Gaia

@MainActor
struct APIKeysSettingsTests {
    @Test func validatesOnlyFilledFieldsAndPreservesPreviouslySavedKeys() async {
        let store = MemoryKeyStore()
        store.keys[.pexels] = "previous"
        var checked: [APIKeyProvider] = []
        let model = APIKeysSettingsModel(storage: store) { provider, _ in
            checked.append(provider)
            return provider == .pexels ? .rejected : .accepted
        }
        #expect(model.drafts[.pexels] == "previous")
        model.edit("replacement", for: .pexels)
        model.edit("   ", for: .unsplash)
        model.edit(" new ", for: .pixabay)
        await model.validateKeys()
        #expect(checked == [.pexels, .pixabay])
        #expect(store.keys == [.pexels: "previous", .pixabay: "new"])
        #expect(model.messages[.pexels] == APIKeyValidation.rejected.rawValue)
        #expect(model.messages[.pixabay] == APIKeyValidation.accepted.rawValue)
        model.remove(.pexels)
        model.remove(.pixabay)
        #expect(!model.canValidate)
        await model.validateKeys()
        #expect(checked.count == 2)
        #expect(store.keys.isEmpty)
    }

    @Test func keychainSupportsAddingReplacingAndRemovingKeys() throws {
        let store = ProviderKeychain(service: "com.madebydaniz.Gaia.tests." + UUID().uuidString)
        defer { try? store.remove(.nasa) }
        #expect(try store.read(.nasa) == nil)
        try store.save("first", for: .nasa)
        #expect(try store.wallpaperKey(for: .nasa) == "first")
        try store.save("second", for: .nasa)
        #expect(try store.wallpaperKey(for: .nasa) == "second")
        try store.remove(.nasa)
        #expect(try store.wallpaperKey(for: .nasa) == AppConfig.Defaults.nasaAPIKey)
    }

    @Test func handlesProviderResponses() {
        let validator = APIKeyValidator()
        func check(_ provider: APIKeyProvider, _ code: Int, _ body: String, _ expected: APIKeyValidation) {
            let request = validator.request(for: provider, key: "dummy")
            let response = HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: nil)!
            #expect(validator.result(for: provider, response: response, data: Data(body.utf8)) == expected)
        }
        check(.pixabay, 400, "[ERROR 400] Invalid API key. Please check the value of the [key] parameter.", .rejected)
        check(.pixabay, 400, "Bad query", .unavailable)
        check(.unsplash, 403, "Rate Limit Exceeded", .rateLimited)
        check(.nasa, 429, "", .rateLimited)
        check(.pexels, 401, "", .rejected)
        check(.pexels, 503, "", .unavailable)
        check(.pexels, 200, "<html>Login</html>", .unavailable)
        check(.pexels, 200, #"{"photos":[]}"#, .accepted)
        check(.pixabay, 200, #"{"hits":[]}"#, .accepted)
        check(.nasa, 200, #"{"date":"2026-10-01"}"#, .accepted)
        check(.unsplash, 200, "[]", .accepted)
    }
}

private final class MemoryKeyStore: ProviderKeyStorage {
    var keys: [APIKeyProvider: String] = [:]
    func read(_ provider: APIKeyProvider) -> String? { keys[provider] }
    func save(_ key: String, for provider: APIKeyProvider) { keys[provider] = key }
    func remove(_ provider: APIKeyProvider) { keys[provider] = nil }
}
