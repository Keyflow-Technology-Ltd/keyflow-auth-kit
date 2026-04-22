//
//  FederatedAuthService.swift
//  KeyflowAuthKit
//
//  High-level façade each iOS app uses. Manages signin, refresh,
//  signout, and handoff flows — wraps KeyflowAuthClient + TokenStore
//  + DeviceIdentity.
//

import Foundation

@MainActor
public final class FederatedAuthService: ObservableObject {
    public let product: KeyflowProduct
    private let client: KeyflowAuthClient
    private let tokenStore: KeyflowTokenStore
    private let deviceIdentity: DeviceIdentity

    @Published public private(set) var isSignedIn: Bool = false
    @Published public private(set) var currentUser: FederatedAuthUser?

    public init(
        product: KeyflowProduct,
        keychainService: String,
        client: KeyflowAuthClient = KeyflowAuthClient(),
    ) {
        self.product = product
        self.client = client
        let keychain = KeyflowKeychain(service: keychainService)
        self.tokenStore = KeyflowTokenStore(keychain: keychain)
        self.deviceIdentity = DeviceIdentity(keychain: keychain)

        Task { await self.restoreSession() }
    }

    /// Rehydrate isSignedIn on launch.
    private func restoreSession() async {
        let token = await tokenStore.accessToken()
        self.isSignedIn = (token != nil)
    }

    public func signIn(email: String, password: String) async throws {
        let deviceId = deviceIdentity.current()
        let response = try await client.signIn(
            email: email,
            password: password,
            product: product,
            deviceId: deviceId,
        )
        await tokenStore.saveSignIn(response)
        self.currentUser = response.user
        self.isSignedIn = true
    }

    public func refresh() async throws {
        guard let refreshToken = await tokenStore.refreshToken() else {
            throw KeyflowAuthError.invalidToken
        }
        let response = try await client.refresh(
            refreshToken: refreshToken,
            product: product,
        )
        await tokenStore.saveRefresh(response)
        self.currentUser = response.user
    }

    public func signOut() async {
        if let refreshToken = await tokenStore.refreshToken() {
            _ = try? await client.signOut(refreshToken: refreshToken, product: product)
        }
        await tokenStore.clear()
        self.isSignedIn = false
        self.currentUser = nil
    }

    public func accessToken() async -> String? {
        await tokenStore.accessToken()
    }

    public func memberships() async throws -> [FederatedMembership] {
        guard let token = await tokenStore.accessToken() else {
            throw KeyflowAuthError.invalidToken
        }
        return try await client.memberships(accessToken: token, product: product)
    }

    public func mintHandoff(to target: KeyflowProduct) async throws -> FederatedHandoffResponse {
        guard let token = await tokenStore.accessToken() else {
            throw KeyflowAuthError.invalidToken
        }
        return try await client.mintHandoff(
            accessToken: token,
            sourceProduct: product,
            targetProduct: target,
        )
    }
}
