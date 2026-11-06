import Foundation
import Security

struct SessionTokens: Codable, Equatable, Sendable {
    let access: String
    let refresh: String?
}

protocol TokenStore: Sendable {
    func load() -> SessionTokens?
    func save(_ tokens: SessionTokens)
    func clear()
}

/// Tokens live in the Keychain, readable only on this device after first unlock.
struct KeychainTokenStore: TokenStore {
    var service = "uz.motohub.app.session"
    var account = "tokens"

    func load() -> SessionTokens? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(SessionTokens.self, from: data)
    }

    func save(_ tokens: SessionTokens) {
        guard let data = try? JSONEncoder().encode(tokens) else { return }
        clear()
        var query = baseQuery
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(query as CFDictionary, nil)
    }

    func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

/// For tests and previews.
final class InMemoryTokenStore: TokenStore, @unchecked Sendable {
    private let lock = NSLock()
    private var tokens: SessionTokens?

    init(_ tokens: SessionTokens? = nil) { self.tokens = tokens }

    func load() -> SessionTokens? { lock.withLock { tokens } }
    func save(_ tokens: SessionTokens) { lock.withLock { self.tokens = tokens } }
    func clear() { lock.withLock { tokens = nil } }
}
