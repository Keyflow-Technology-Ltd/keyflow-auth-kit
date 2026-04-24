//
//  AIAction.swift
//  KeyflowAIKit
//
//  The contract every AI suggestion in the Keyflow ecosystem conforms to.
//  Lead scoring, renewal proposals, listing-buyer matches, cheque parsers —
//  every surface that suggests a next action implements this protocol so
//  the notification, approval, and telemetry layers treat them uniformly.
//

import Foundation

/// One concrete AI suggestion shown to the user.
///
/// Implementations capture (a) what to do, (b) why, (c) how confident the
/// model is, and (d) the accept/reject side effects. The Action Inbox
/// wraps these, surfaces them as rich notifications with quick-actions,
/// and records telemetry via KeyflowEventsKit.
public protocol AIAction: Sendable {
    /// Stable identity across renders. Used for deduplication, telemetry
    /// correlation, and the `Yes, always` auto-approve preferences (which
    /// key off `kind`, not `id`).
    var id: String { get }

    /// The *type* of action — `"auto_reply"`, `"rent_proposal"`, etc.
    /// Used by the Action Inbox to group suggestions and key the
    /// per-type auto-approve preference.
    var kind: String { get }

    /// User-facing headline. Shown in notifications + inbox.
    var title: String { get }

    /// Optional detail shown when the user taps "Why?" — the model's
    /// justification. Keep under 500 chars; no PII.
    var rationale: String? { get }

    /// 0.0–1.0. Gates auto-approve — if the user has enabled
    /// `Yes, always` for this `kind`, actions with `confidence >= kind
    /// threshold` auto-accept. Below threshold still prompts.
    var confidence: Double { get }

    /// The telemetry breadcrumb — which `KeyflowEvent.*` values
    /// triggered this suggestion. Debugging aid + signal for
    /// live-cadence replay.
    var sourceEvents: [String] { get }

    /// Which product this action applies to. Keeps cross-product
    /// suggestions routable.
    var product: String { get }

    /// Apply the suggestion. Called from `.accept()` path.
    func accept() async throws

    /// Dismiss without side effects. Called from `.reject()` path.
    func reject() async throws
}

public extension AIAction {
    /// Default: no rationale.
    var rationale: String? { nil }
}
