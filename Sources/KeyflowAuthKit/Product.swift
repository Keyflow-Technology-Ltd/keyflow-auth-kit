//
//  Product.swift
//  KeyflowAuthKit
//
//  Canonical enum for the three Keyflow products. Each value maps 1:1
//  to the `aud` claim the auth service puts on issued tokens.
//

import Foundation

public enum KeyflowProduct: String, Codable, Sendable {
    case leadsflow = "LEADSFLOW"
    case dealsflow = "DEALSFLOW"
    case leaseflow = "LEASEFLOW"

    /// The value that ends up in the JWT `aud` claim.
    public var audience: String {
        switch self {
        case .leadsflow: return "leadsflow"
        case .dealsflow: return "dealsflow"
        case .leaseflow: return "leaseflow"
        }
    }

    /// The native deep-link scheme for the product — used when minting
    /// handoff tokens to open another product's app.
    public var urlScheme: String {
        switch self {
        case .leadsflow: return "leadsflow"
        case .dealsflow: return "dealsflow"
        case .leaseflow: return "leaseflow"
        }
    }
}
