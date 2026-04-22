//
//  AuthClient.swift
//  KeyflowAuthKit
//
//  HTTP client for auth.keyflowae.com. Wraps the 10 routes documented
//  in Keyflow/docs/sso-architecture.md §5.1.
//

import Foundation

public struct KeyflowAuthClient: Sendable {
    public let baseURL: URL
    public let session: URLSession

    public init(
        baseURL: URL = URL(string: "https://auth.keyflowae.com")!,
        session: URLSession = .shared,
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Signin / Refresh / Signout

    public func signIn(
        email: String,
        password: String,
        product: KeyflowProduct,
        deviceId: String,
    ) async throws -> FederatedSignInResponse {
        struct Body: Encodable {
            let email: String
            let password: String
            let product: String
            let deviceId: String
        }
        let body = Body(
            email: email,
            password: password,
            product: product.rawValue,
            deviceId: deviceId,
        )
        return try await send(path: "/api/signin", method: "POST", body: body)
    }

    public func refresh(
        refreshToken: String,
        product: KeyflowProduct,
    ) async throws -> FederatedRefreshResponse {
        struct Body: Encodable {
            let refreshToken: String
            let product: String
        }
        return try await send(
            path: "/api/refresh",
            method: "POST",
            body: Body(refreshToken: refreshToken, product: product.rawValue),
        )
    }

    public func signOut(
        refreshToken: String,
        product: KeyflowProduct,
    ) async throws {
        struct Body: Encodable {
            let refreshToken: String
            let product: String
        }
        struct Reply: Decodable { let revoked: Bool }
        let _: Reply = try await send(
            path: "/api/signout",
            method: "POST",
            body: Body(refreshToken: refreshToken, product: product.rawValue),
        )
    }

    // MARK: - Memberships / Handoff

    public func memberships(
        accessToken: String,
        product: KeyflowProduct,
    ) async throws -> [FederatedMembership] {
        struct Reply: Decodable { let memberships: [FederatedMembership] }
        let reply: Reply = try await send(
            path: "/api/memberships",
            method: "GET",
            body: Optional<EmptyBody>.none,
            accessToken: accessToken,
            product: product,
        )
        return reply.memberships
    }

    public func mintHandoff(
        accessToken: String,
        sourceProduct: KeyflowProduct,
        targetProduct: KeyflowProduct,
    ) async throws -> FederatedHandoffResponse {
        struct Body: Encodable { let targetProduct: String }
        return try await send(
            path: "/api/handoff/mint",
            method: "POST",
            body: Body(targetProduct: targetProduct.rawValue),
            accessToken: accessToken,
            product: sourceProduct,
        )
    }

    // MARK: - Password reset

    public func forgotPassword(email: String) async throws {
        struct Body: Encodable { let email: String }
        struct Reply: Decodable { let message: String }
        let _: Reply = try await send(
            path: "/api/forgot-password",
            method: "POST",
            body: Body(email: email),
        )
    }

    public func resetPassword(token: String, newPassword: String) async throws {
        struct Body: Encodable {
            let token: String
            let newPassword: String
        }
        struct Reply: Decodable { let success: Bool }
        let _: Reply = try await send(
            path: "/api/reset-password",
            method: "POST",
            body: Body(token: token, newPassword: newPassword),
        )
    }

    // MARK: - Session status (used by product backends, exposed here
    // for debugging / admin tools)

    public func sessionStatus(
        id: String,
        accessToken: String,
        product: KeyflowProduct,
    ) async throws -> SessionStatus {
        return try await send(
            path: "/api/sessions/\(id)",
            method: "GET",
            body: Optional<EmptyBody>.none,
            accessToken: accessToken,
            product: product,
        )
    }

    public struct SessionStatus: Decodable, Sendable {
        public let valid: Bool
        public let revokedAt: Date?
        public let blocked: Bool
        public let blockedReason: String?
    }

    // MARK: - Internal

    private struct EmptyBody: Encodable {}

    private struct APIEnvelope<T: Decodable>: Decodable {
        let success: Bool
        let data: T?
        let error: APIError?
        struct APIError: Decodable {
            let code: String
            let message: String
            let details: JSONValue?
        }
    }

    // Token-ish JSON so we can decode Details of unknown shape.
    private enum JSONValue: Decodable {
        case object([String: JSONValue])
        case array([JSONValue])
        case string(String)
        case number(Double)
        case bool(Bool)
        case null
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if c.decodeNil() { self = .null }
            else if let v = try? c.decode(Bool.self) { self = .bool(v) }
            else if let v = try? c.decode(Double.self) { self = .number(v) }
            else if let v = try? c.decode(String.self) { self = .string(v) }
            else if let v = try? c.decode([JSONValue].self) { self = .array(v) }
            else if let v = try? c.decode([String: JSONValue].self) { self = .object(v) }
            else { self = .null }
        }
    }

    private func send<Body: Encodable, Reply: Decodable>(
        path: String,
        method: String,
        body: Body?,
        accessToken: String? = nil,
        product: KeyflowProduct? = nil,
    ) async throws -> Reply {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        if let product {
            request.setValue(product.rawValue, forHTTPHeaderField: "X-Keyflow-Product")
        }
        if let body = body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .useDefaultKeys
            request.httpBody = try encoder.encode(body)
        }

        let (data, resp): (Data, URLResponse)
        do {
            (data, resp) = try await session.data(for: request)
        } catch {
            throw KeyflowAuthError.network(error)
        }

        guard let http = resp as? HTTPURLResponse else {
            throw KeyflowAuthError.network(URLError(.badServerResponse))
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if (200..<300).contains(http.statusCode) {
            // Auth service wraps everything in { success, data }.
            if let envelope = try? decoder.decode(APIEnvelope<Reply>.self, from: data),
               envelope.success, let inner = envelope.data {
                return inner
            }
            // Fall through to direct decode for callers that return raw shapes.
            do {
                return try decoder.decode(Reply.self, from: data)
            } catch {
                throw KeyflowAuthError.decoding(error)
            }
        }

        // Error path — map well-known codes.
        let envelope = try? decoder.decode(APIEnvelope<Reply>.self, from: data)
        let code = envelope?.error?.code ?? "HTTP_\(http.statusCode)"
        let message = envelope?.error?.message ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)

        switch (http.statusCode, code) {
        case (401, "INVALID_CREDENTIALS"):
            throw KeyflowAuthError.invalidCredentials(message: message)
        case (403, "ACCOUNT_BLOCKED"):
            let reason = extractReason(envelope) ?? "UNKNOWN"
            throw KeyflowAuthError.accountBlocked(reason: reason)
        case (429, "ACCOUNT_LOCKED"):
            throw KeyflowAuthError.accountLocked(message: message)
        case (403, "NO_MEMBERSHIP"):
            throw KeyflowAuthError.noMembership(product: product ?? .leadsflow)
        case (429, "RATE_LIMITED"):
            let retry = http.value(forHTTPHeaderField: "Retry-After").flatMap(Double.init)
            throw KeyflowAuthError.rateLimited(retryAfter: retry)
        case (401, "SESSION_REVOKED"):
            throw KeyflowAuthError.sessionRevoked
        case (401, "INVALID_TOKEN"):
            throw KeyflowAuthError.invalidToken
        default:
            throw KeyflowAuthError.server(status: http.statusCode, code: code, message: message)
        }
    }

    private func extractReason<T>(_ envelope: APIEnvelope<T>?) -> String? {
        guard case .object(let obj)? = envelope?.error?.details,
              case .string(let value)? = obj["reason"] else { return nil }
        return value
    }
}
