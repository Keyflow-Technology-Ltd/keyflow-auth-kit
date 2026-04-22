//
//  Models.swift
//  KeyflowAuthKit
//
//  Wire types mirroring the auth.keyflowae.com API response shapes.
//

import Foundation

public struct FederatedAuthUser: Codable, Sendable {
    public let keyflowUid: String
    public let email: String
    public let productUserId: String
    public let role: String
    public let tenantId: String
    public let tenantName: String
}

public struct FederatedSignInResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let user: FederatedAuthUser
}

public struct FederatedRefreshResponse: Codable, Sendable {
    public let accessToken: String
    public let expiresIn: Int
    public let user: FederatedAuthUser
}

public struct FederatedMembership: Codable, Identifiable, Sendable {
    public let id: String
    public let product: String
    public let productUserId: String
    public let tenantId: String
    public let tenantName: String
    public let role: String
}

public struct FederatedHandoffResponse: Codable, Sendable {
    public struct Target: Codable, Sendable {
        public let product: String
        public let productUserId: String
        public let tenantId: String
    }
    public let handoffToken: String
    public let expiresIn: Int
    public let target: Target
}

/// Errors surfaced by the auth client. iOS call sites can pattern-match
/// on the cases for user-friendly messages without parsing JSON twice.
public enum KeyflowAuthError: Error, Sendable {
    case invalidCredentials(message: String)
    case accountBlocked(reason: String)
    case accountLocked(message: String)
    case noMembership(product: KeyflowProduct)
    case rateLimited(retryAfter: TimeInterval?)
    case sessionRevoked
    case invalidToken
    case network(Error)
    case server(status: Int, code: String?, message: String)
    case decoding(Error)
}
