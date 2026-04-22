//
//  Keychain.swift
//  KeyflowAuthKit
//
//  Shared Keychain wrapper. Replaces each product's per-app
//  KeychainService once the apps migrate to KeyflowAuthKit.
//

import Foundation
import Security

/// Thin, app-agnostic Keychain accessor. Each product isolates its
/// storage via a distinct service prefix passed in on init.
public struct KeyflowKeychain: Sendable {
    public let service: String

    public init(service: String) {
        self.service = service
    }

    public func set(_ value: String, for key: String) -> Bool {
        delete(key)
        let data = Data(value.utf8)
        var attrs: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        return SecItemAdd(attrs as CFDictionary, nil) == errSecSuccess
    }

    public func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else { return nil }
        return value
    }

    @discardableResult
    public func delete(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
