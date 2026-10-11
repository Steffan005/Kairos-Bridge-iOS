// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
import Foundation
import Security

/// Foreground-only, device-bound Keychain storage. Never stores the password.
struct SessionVault {
    struct Cookie: Codable {
        let name: String
        let value: String
        let domain: String
        let path: String
        let expires: Date?
    }

    struct Session: Codable {
        var email: String?
        var cookies: [Cookie]
    }

    private let service = "com.steffanhaskins.kairos.staging-session"
    private let account = "owner-session"

    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service, kSecAttrAccount as String: account]
    }

    func load() throws -> Session? {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw KairosFailure.secureStorage }
        return try JSONDecoder().decode(Session.self, from: data)
    }

    func save(_ session: Session) throws {
        let data = try JSONEncoder().encode(session)
        let update = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            var request = query
            request[kSecValueData as String] = data
            request[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(request as CFDictionary, nil) == errSecSuccess else { throw KairosFailure.secureStorage }
        } else if status != errSecSuccess { throw KairosFailure.secureStorage }
    }

    func clear() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KairosFailure.secureStorage }
    }
}
