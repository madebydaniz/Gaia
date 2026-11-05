import Foundation
import Security

enum APIKeyProvider: String, CaseIterable {
    case nasa = "NASA"
    case pexels = "Pexels"
    case pixabay = "Pixabay"
    case unsplash = "Unsplash"
}

protocol ProviderKeyStorage {
    func read(_ provider: APIKeyProvider) throws -> String?
    func save(_ key: String, for provider: APIKeyProvider) throws
    func remove(_ provider: APIKeyProvider) throws
}

struct ProviderKeychain: ProviderKeyStorage {
    var service = "com.madebydaniz.Gaia.provider-keys"

    private func query(_ provider: APIKeyProvider) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue
        ]
    }

    func read(_ provider: APIKeyProvider) throws -> String? {
        var attributes = query(provider)
        attributes[kSecReturnData as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(attributes as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        try check(status)
        guard let data = result as? Data, let key = String(data: data, encoding: .utf8) else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(errSecDecode))
        }
        return key
    }

    func save(_ key: String, for provider: APIKeyProvider) throws {
        var attributes = query(provider)
        let value = [kSecValueData as String: Data(key.utf8)]
        let status = SecItemUpdate(attributes as CFDictionary, value as CFDictionary)
        if status == errSecItemNotFound {
            attributes.merge(value) { _, new in new }
            try check(SecItemAdd(attributes as CFDictionary, nil))
        } else {
            try check(status)
        }
    }

    func remove(_ provider: APIKeyProvider) throws {
        let status = SecItemDelete(query(provider) as CFDictionary)
        if status != errSecItemNotFound { try check(status) }
    }

    func wallpaperKey(for provider: APIKeyProvider) throws -> String {
        if let key = try read(provider) { return key }
        if provider == .nasa { return AppConfig.Defaults.nasaAPIKey }
        throw NetworkError.unknown(String(format: NSLocalizedString("apiKeys.missing", comment: ""), provider.rawValue))
    }

    private func check(_ status: OSStatus) throws {
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
}
