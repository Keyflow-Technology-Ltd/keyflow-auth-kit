//
//  AIActionDispatcher.swift
//  KeyflowAIKit
//
//  Runs AIAction accept/reject paths uniformly, so every product's
//  telemetry + auto-approve preferences + error surfacing look the same.
//

import Foundation
import KeyflowEventsKit

/// Outcome of one AIAction lifecycle. Emitted to observers so UI layers
/// can update inbox badges + notification states without touching the
/// action itself.
public enum AIActionOutcome: Sendable {
    case shown
    case accepted
    case rejected
    case autoAccepted
    case rationaleViewed
    case failed(Error)
}

/// Callback surface for anything that cares about AIAction lifecycle —
/// the Action Inbox, PostHog bridge, local haptics, etc.
public protocol AIActionObserver: AnyObject, Sendable {
    func aiAction(_ action: AIAction, outcome: AIActionOutcome)
}

/// The sole entry point for emitting + handling AIActions. Keeps the
/// telemetry/UX contract identical across products.
@MainActor
public final class AIActionDispatcher {
    public static let shared = AIActionDispatcher()

    /// Per-`kind` auto-approve confidence threshold. When the user taps
    /// "Yes, always auto-approve", we store the action's current
    /// confidence here. Future actions of the same kind with
    /// confidence ≥ threshold skip the prompt.
    ///
    /// Persisted to UserDefaults under `"KeyflowAIKit.autoApprove"`.
    private var autoApprove: [String: Double] {
        get { UserDefaults.standard.dictionary(forKey: Self.autoApproveKey) as? [String: Double] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: Self.autoApproveKey) }
    }

    private static let autoApproveKey = "KeyflowAIKit.autoApprove"

    private var observers: [AIActionObserver] = []

    private init() {}

    public func addObserver(_ observer: AIActionObserver) {
        observers.append(observer)
    }

    public func removeObserver(_ observer: AIActionObserver) {
        observers.removeAll { $0 === observer }
    }

    /// Record that an action was presented. Emits `ai_suggestion_shown`.
    public func present(_ action: AIAction) {
        notify(action, .shown)
    }

    /// User accepted the suggestion. Runs `action.accept()`, emits
    /// `ai_suggestion_accepted`, or `ai_suggestion_auto_accepted` if the
    /// auto-approve threshold was met.
    public func accept(_ action: AIAction, autoApproved: Bool = false) async {
        do {
            try await action.accept()
            notify(action, autoApproved ? .autoAccepted : .accepted)
        } catch {
            notify(action, .failed(error))
        }
    }

    /// User rejected the suggestion. Emits `ai_suggestion_rejected`.
    public func reject(_ action: AIAction) async {
        do {
            try await action.reject()
            notify(action, .rejected)
        } catch {
            notify(action, .failed(error))
        }
    }

    /// User tapped "Yes, always auto-approve". Stores the threshold at
    /// the action's current confidence — future actions of the same
    /// kind with equal-or-higher confidence will auto-accept.
    public func enableAutoApprove(for action: AIAction) {
        var current = autoApprove
        current[action.kind] = action.confidence
        autoApprove = current
    }

    public func disableAutoApprove(forKind kind: String) {
        var current = autoApprove
        current.removeValue(forKey: kind)
        autoApprove = current
    }

    public func autoApproveThreshold(forKind kind: String) -> Double? {
        autoApprove[kind]
    }

    /// Returns true if this action should auto-accept. Callers invoke
    /// `.accept(_, autoApproved: true)` in that case instead of
    /// surfacing a prompt.
    public func shouldAutoApprove(_ action: AIAction) -> Bool {
        guard let threshold = autoApprove[action.kind] else { return false }
        return action.confidence >= threshold
    }

    /// User expanded the "Why?" disclosure. Emits
    /// `ai_suggestion_rationale_viewed` for telemetry.
    public func rationaleViewed(_ action: AIAction) {
        notify(action, .rationaleViewed)
    }

    // MARK: Private

    private func notify(_ action: AIAction, _ outcome: AIActionOutcome) {
        for observer in observers {
            observer.aiAction(action, outcome: outcome)
        }
    }
}

/// Map `AIActionOutcome` → canonical `KeyflowEvent`. Kept on the type
/// so observers can reuse without re-deriving the mapping.
public extension AIActionOutcome {
    var keyflowEvent: KeyflowEvent? {
        switch self {
        case .shown: return .aiSuggestionShown
        case .accepted: return .aiSuggestionAccepted
        case .rejected: return .aiSuggestionRejected
        case .autoAccepted: return .aiSuggestionAutoAccepted
        case .rationaleViewed: return .aiSuggestionRationaleViewed
        case .failed: return nil
        }
    }
}
