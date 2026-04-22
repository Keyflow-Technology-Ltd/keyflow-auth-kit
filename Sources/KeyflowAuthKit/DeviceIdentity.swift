//
//  DeviceIdentity.swift
//  KeyflowAuthKit
//
//  Per-install UUID persisted in the Keychain. Sent as the `deviceId`
//  claim on auth.keyflowae.com signin. Mirrors each product's local
//  DeviceIdentityService implementation so those can be deleted once
//  apps migrate onto KeyflowAuthKit.
//

import Foundation

public struct DeviceIdentity: Sendable {
    public static let key = "deviceId"

    let keychain: KeyflowKeychain

    public init(keychain: KeyflowKeychain) {
        self.keychain = keychain
    }

    /// Returns the stored device id, creating a new one on first call.
    /// Never fails: falls back to an in-memory UUID if the Keychain
    /// write is rejected so signin is never blocked here.
    public func current() -> String {
        if let existing = keychain.get(Self.key), !existing.isEmpty {
            return existing
        }
        let fresh = UUID().uuidString
        _ = keychain.set(fresh, for: Self.key)
        return fresh
    }
}
