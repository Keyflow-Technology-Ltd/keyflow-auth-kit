//
//  AIActionStore.swift
//  KeyflowActionInboxUI
//
//  In-memory store of pending + history AIActions. Publishes changes to
//  SwiftUI via @Observable. Plugs into AIActionDispatcher as an observer
//  so every product wires into the inbox just by emitting actions
//  through the dispatcher.
//

import Foundation
import Observation
import KeyflowAIKit

/// A mutable AIAction entry — same logical action across its lifecycle.
/// We box AIActions in a non-sendable reference wrapper because the
/// inbox needs identity stability while the underlying action's
/// confidence or title may refresh as the live-cadence engine recomputes.
public final class InboxEntry: Identifiable, Hashable {
    public let id: String
    public fileprivate(set) var action: AIAction
    public fileprivate(set) var state: State
    public let createdAt: Date
    public fileprivate(set) var resolvedAt: Date?

    public enum State: Sendable {
        case pending
        case accepted
        case autoAccepted
        case rejected
        case failed(String)
    }

    init(action: AIAction) {
        self.id = action.id
        self.action = action
        self.state = .pending
        self.createdAt = Date()
    }

    public static func == (lhs: InboxEntry, rhs: InboxEntry) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Observable store backing the inbox UI. One instance per app.
/// Products register it with `AIActionDispatcher.shared.addObserver(store)`
/// at launch; every action flows through here automatically.
@Observable @MainActor
public final class AIActionStore: AIActionObserver {
    public private(set) var pending: [InboxEntry] = []
    public private(set) var history: [InboxEntry] = []

    /// History cap — dropping oldest past this size keeps memory bounded
    /// on long-running sessions.
    private let historyLimit = 200

    public init() {}

    /// Convenience — inject fresh actions from the app (e.g. cadence
    /// engine recomputed, new match arrived) without them being a
    /// "shown" telemetry hit yet.
    public func insert(_ action: AIAction) {
        if let existing = pending.first(where: { $0.id == action.id }) {
            existing.action = action
            return
        }
        let entry = InboxEntry(action: action)
        pending.append(entry)
        AIActionDispatcher.shared.present(action)
    }

    // MARK: AIActionObserver

    public nonisolated func aiAction(_ action: AIAction, outcome: AIActionOutcome) {
        Task { @MainActor in
            self.apply(action: action, outcome: outcome)
        }
    }

    private func apply(action: AIAction, outcome: AIActionOutcome) {
        let entry = pending.first(where: { $0.id == action.id })
            ?? history.first(where: { $0.id == action.id })

        switch outcome {
        case .shown:
            if entry == nil {
                pending.append(InboxEntry(action: action))
            }
        case .accepted:
            resolve(action: action, state: .accepted)
        case .autoAccepted:
            resolve(action: action, state: .autoAccepted)
        case .rejected:
            resolve(action: action, state: .rejected)
        case .rationaleViewed:
            break
        case .failed(let err):
            resolve(action: action, state: .failed(String(describing: err)))
        }
    }

    private func resolve(action: AIAction, state: InboxEntry.State) {
        guard let idx = pending.firstIndex(where: { $0.id == action.id }) else { return }
        let entry = pending.remove(at: idx)
        entry.state = state
        entry.resolvedAt = Date()
        history.insert(entry, at: 0)
        if history.count > historyLimit {
            history.removeLast(history.count - historyLimit)
        }
    }
}
