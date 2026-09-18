import AppKit
import SwiftUI

struct ContextualRecallView: View {
    @EnvironmentObject private var incidentStore: IncidentStore
    @EnvironmentObject private var accomplishmentStore: AccomplishmentStore
    @EnvironmentObject private var graphStore: WorkGraphStore

    let subject: WorkGraphNodeRef

    @State private var resultLimit = 8
    @State private var selectedIDs: Set<String> = []
    @State private var preview = ""

    private var results: [ContextualRecallResult] {
        ContextualRecallEngine.recall(
            for: subject,
            incidents: incidentStore,
            accomplishments: accomplishmentStore,
            graph: graphStore,
            limit: resultLimit
        )
    }

    private var selectedResults: [ContextualRecallResult] {
        results.filter { selectedIDs.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Contextual Recall").font(.headline)
                    Text("Related history is ranked locally. Explicit graph links outrank inferred similarity, and every result shows why it was retrieved.")
                        .font(.callout).foregroundStyle(ESTheme.muted)
                }
                Spacer()
                Stepper("Results: \(resultLimit)", value: $resultLimit, in: 3...20)
                    .frame(width: 145)
            }

            if results.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 38, weight: .light)).foregroundStyle(ESTheme.gold)
                    Text("No related history has enough signal yet.").font(.system(size: 14, weight: .semibold))
                    Text("Add explicit Work Graph relationships or consistent tags, systems, projects, and record language. Recall will improve without changing the underlying evidence.")
                        .font(.callout).foregroundStyle(ESTheme.muted).multilineTextAlignment(.center).frame(maxWidth: 620)
                }
                .frame(maxWidth: .infinity, minHeight: 260)
                .padding(16).panelBackground()
            } else {
                HStack {
                    Button("Select High-Confidence") {
                        selectedIDs = Set(results.filter { $0.score >= 65 }.map(\.id))
                        refreshPreview()
                    }
                    .buttonStyle(.bordered)

                    Button("Select All") {
                        selectedIDs = Set(results.map(\.id))
                        refreshPreview()
                    }
                    .buttonStyle(.bordered)

                    Button("Clear") {
                        selectedIDs.removeAll()
                        preview = ""
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Build Context Preview") { refreshPreview() }
                        .buttonStyle(.borderedProminent).tint(ESTheme.accent)
                        .disabled(selectedResults.isEmpty)
                }

                VStack(spacing: 10) {
                    ForEach(results) { result in
                        recallRow(result)
                    }
                }

                if !preview.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AI Context Preview").font(.system(size: 13, weight: .semibold))
                                Text("Inspect this bounded context before using it with Apple Intelligence.")
                                    .font(.caption).foregroundStyle(ESTheme.muted)
                            }
                            Spacer()
                            Button("Copy Context") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(preview, forType: .string)
                            }
                        }
                        TextEditor(text: .constant(preview))
                            .font(.system(size: 12, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .frame(minHeight: 240)
                            .background(ESTheme.field)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))
                    }
                    .padding(14).panelBackground()
                }
            }
        }
        .onAppear {
            if selectedIDs.isEmpty {
                selectedIDs = Set(results.filter { $0.score >= 65 }.map(\.id))
            }
        }
        .onChange(of: resultLimit) { _, _ in
            selectedIDs = selectedIDs.intersection(Set(results.map(\.id)))
            if !preview.isEmpty { refreshPreview() }
        }
    }

    private func recallRow(_ result: ContextualRecallResult) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: Binding(
                get: { selectedIDs.contains(result.id) },
                set: { isOn in
                    if isOn { selectedIDs.insert(result.id) }
                    else { selectedIDs.remove(result.id) }
                }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)

            Image(systemName: result.node.kind.symbol)
                .foregroundStyle(result.score >= 65 ? ESTheme.gold : ESTheme.accent)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(result.node.title).font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text(result.confidenceLabel.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(result.score >= 65 ? ESTheme.gold : ESTheme.muted)
                    Text("\(Int(result.score.rounded()))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(ESTheme.muted)
                }
                Text(result.node.subtitle).font(.caption).foregroundStyle(ESTheme.muted)
                if let date = result.node.date {
                    Text(date.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(ESTheme.muted)
                }
                Text(result.reasons.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(12)
        .background(ESTheme.panelRaised)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))
    }

    private func refreshPreview() {
        preview = ContextualRecallEngine.contextBundle(
            subject: subject,
            selected: selectedResults,
            incidents: incidentStore,
            accomplishments: accomplishmentStore,
            graph: graphStore
        )
    }
}
