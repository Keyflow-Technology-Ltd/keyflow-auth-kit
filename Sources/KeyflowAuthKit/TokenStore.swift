//
//  TokenStore.swift
//  KeyflowAuthKit
//
//  Persists the access + refresh token pair in the Keychain and caches
//  the current access token in memory. Designed to be a drop-in for
//  each product's existing token storage once they migrate.
//

import Foundation

public actor KeyflowTokenStore {
    private let keychain: KeyflowKeychain

    private enum Keys {
        static let accessToken = "federated_access_token"
        static let refreshToken = "federated_refresh_token"
        static let email = "federated_email"
        static let keyflowUid = "federated_keyflow_uid"
    }

    // In-memory cache so we don't hit the Keychain on every request.
    private var cachedAccessToken: String?

    public init(keychain: KeyflowKeychain) {
        self.keychain = keychain
        self.cachedAccessToken = keychain.get(Keys.accessToken)
    }

    public func accessToken() -> String? {
        cachedAccessToken
    }

    public func refreshToken() -> String? {
        keychain.get(Keys.refreshToken)
    }

    public func email() -> String? {
        keychain.get(Keys.email)
    }

    public func keyflowUid() -> String? {
        keychain.get(Keys.keyflowUid)
    }

    public func saveSignIn(_ response: FederatedSignInResponse) {
        _ = keychain.set(response.accessToken, for: Keys.accessToken)
        _ = keychain.set(response.refreshToken, for: Keys.refreshToken)
        _ = keychain.set(response.user.email, for: Keys.email)
        _ = keychain.set(response.user.keyflowUid, for: Keys.keyflowUid)
        cachedAccessToken = response.accessToken
    }

    public func saveRefresh(_ response: FederatedRefreshResponse) {
        _ = keychain.set(response.accessToken, for: Keys.accessToken)
        cachedAccessToken = response.accessToken
    }

    public func clear() {
        keychain.delete(Keys.accessToken)
        keychain.delete(Keys.refreshToken)
        keychain.delete(Keys.email)
        keychain.delete(Keys.keyflowUid)
        cachedAccessToken = nil
    }
}
