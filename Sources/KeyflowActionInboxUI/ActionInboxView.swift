//
//  ActionInboxView.swift
//  KeyflowActionInboxUI
//
//  SwiftUI inbox surface. Renders the AIActionStore.pending list with a
//  row per suggestion. Tap opens the detail sheet with accept/reject +
//  rationale disclosure.
//
//  This is intentionally unstyled — each product applies its own
//  KeyflowDesignKit tokens via the `.actionInboxStyle` modifier. The
//  layout + affordances stay identical across products.
//

import SwiftUI
import KeyflowAIKit

public struct ActionInboxView: View {
    @Bindable public var store: AIActionStore
    @State private var selected: InboxEntry?

    public init(store: AIActionStore) {
        self.store = store
    }

    public var body: some View {
        List {
            Section("Pending (\(store.pending.count))") {
                if store.pending.isEmpty {
                    Text("No suggestions right now")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(store.pending) { entry in
                        Button {
                            selected = entry
                        } label: {
                            ActionRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !store.history.isEmpty {
                Section("Recent") {
                    ForEach(store.history.prefix(20)) { entry in
                        HistoryRow(entry: entry)
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .navigationTitle("Suggestions")
        .sheet(item: $selected) { entry in
            ActionDetailSheet(entry: entry)
        }
    }
}

struct ActionRow: View {
    let entry: InboxEntry

    var body: some View {
        HStack(spacing: 12) {
            ConfidenceBadge(confidence: entry.action.confidence)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.action.title)
                    .font(.body.weight(.medium))
                    .lineLimit(2)
                Text(entry.action.kind.replacingOccurrences(of: "_", with: " "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct HistoryRow: View {
    let entry: InboxEntry

    var body: some View {
        HStack(spacing: 12) {
            stateIcon
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.action.title)
                    .font(.subheadline)
                    .lineLimit(1)
                if let resolvedAt = entry.resolvedAt {
                    Text(resolvedAt.formatted(.relative(presentation: .numeric)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
        }
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch entry.state {
        case .pending:
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
        case .accepted:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .autoAccepted:
            Image(systemName: "bolt.fill")
                .foregroundStyle(.blue)
        case .rejected:
            Image(systemName: "xmark.circle")
                .foregroundStyle(.secondary)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
    }
}

struct ConfidenceBadge: View {
    let confidence: Double

    var body: some View {
        Text("\(Int(confidence * 100))%")
            .font(.caption2.weight(.semibold))
            .frame(width: 44, height: 22)
            .foregroundStyle(.white)
            .background(color, in: Capsule())
    }

    private var color: Color {
        switch confidence {
        case 0.8...: return .green
        case 0.5..<0.8: return .blue
        default: return .orange
        }
    }
}

public struct ActionDetailSheet: View {
    let entry: InboxEntry
    @State private var showRationale = false
    @State private var isRunning = false
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(entry.action.title)
                        .font(.title3.weight(.semibold))
                    ConfidenceBadge(confidence: entry.action.confidence)
                }

                if let rationale = entry.action.rationale {
                    Section("Why") {
                        DisclosureGroup(isExpanded: $showRationale) {
                            Text(rationale)
                                .font(.body)
                        } label: {
                            Label("Show reasoning", systemImage: "sparkles")
                        }
                        .onChange(of: showRationale) { _, newValue in
                            if newValue {
                                AIActionDispatcher.shared.rationaleViewed(entry.action)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        perform { await AIActionDispatcher.shared.accept(entry.action) }
                    } label: {
                        Label("Accept", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRunning)

                    Button {
                        AIActionDispatcher.shared.enableAutoApprove(for: entry.action)
                        perform {
                            await AIActionDispatcher.shared.accept(entry.action, autoApproved: true)
                        }
                    } label: {
                        Label("Yes, always auto-approve", systemImage: "bolt.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRunning)

                    Button(role: .destructive) {
                        perform { await AIActionDispatcher.shared.reject(entry.action) }
                    } label: {
                        Label("Reject", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRunning)
                }
            }
            .navigationTitle("Suggestion")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func perform(_ work: @escaping () async -> Void) {
        isRunning = true
        Task {
            await work()
            await MainActor.run { dismiss() }
        }
    }
}
