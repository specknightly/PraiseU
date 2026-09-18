import SwiftUI

struct RelationshipEditorView: View {
    @EnvironmentObject private var incidentStore: IncidentStore
    @EnvironmentObject private var accomplishmentStore: AccomplishmentStore
    @EnvironmentObject private var graphStore: WorkGraphStore

    let subject: WorkGraphNodeRef

    @State private var target: WorkGraphNodeRef?
    @State private var relationship: WorkGraphRelationshipKind = .relatedTo
    @State private var note = ""
    @State private var entityKind: WorkGraphNodeKind = .person
    @State private var entityName = ""
    @State private var entityNotes = ""

    private var catalog: [WorkGraphCatalogNode] {
        WorkGraphCatalog.nodes(incidents: incidentStore, accomplishments: accomplishmentStore, graph: graphStore)
    }

    private var availableTargets: [WorkGraphCatalogNode] { catalog.filter { $0.ref != subject } }
    private var subjectNode: WorkGraphCatalogNode? { catalog.first { $0.ref == subject } }
    private var existingLinks: [WorkGraphLink] { graphStore.links(for: subject) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: subject.kind.symbol).foregroundStyle(ESTheme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Relationship-Aware Work Graph").font(.headline)
                    Text(subjectNode?.title ?? subject.kind.rawValue).font(.caption).foregroundStyle(ESTheme.muted)
                }
                Spacer()
                Text("\(existingLinks.count) link\(existingLinks.count == 1 ? "" : "s")")
                    .font(.caption.monospacedDigit()).foregroundStyle(ESTheme.muted)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Connect this record").font(.system(size: 13, weight: .semibold))
                HStack(spacing: 10) {
                    Picker("Relationship", selection: $relationship) {
                        ForEach(WorkGraphRelationshipKind.allCases) { item in Text(item.rawValue).tag(item) }
                    }.frame(width: 220)
                    Picker("Target", selection: $target) {
                        Text("Choose a node…").tag(Optional<WorkGraphNodeRef>.none)
                        ForEach(availableTargets) { node in
                            Text("\(node.kind.rawValue): \(node.title)").tag(Optional(node.ref))
                        }
                    }.frame(maxWidth: .infinity)
                }
                TextField("Relationship note (optional)", text: $note)
                HStack {
                    Spacer()
                    Button("Add Relationship") { addRelationship() }
                        .buttonStyle(.borderedProminent).tint(ESTheme.accent).disabled(target == nil)
                }
            }
            .padding(14).panelBackground()

            VStack(alignment: .leading, spacing: 10) {
                Text("Quick-create a person, system, or project").font(.system(size: 13, weight: .semibold))
                HStack {
                    Picker("Type", selection: $entityKind) {
                        Text("Person").tag(WorkGraphNodeKind.person)
                        Text("System").tag(WorkGraphNodeKind.system)
                        Text("Project").tag(WorkGraphNodeKind.project)
                    }.frame(width: 150)
                    TextField("Name", text: $entityName)
                    TextField("Notes (optional)", text: $entityNotes)
                    Button("Create & Link") { createEntityAndLink() }
                        .disabled(entityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(14).panelBackground()

            VStack(alignment: .leading, spacing: 10) {
                Text("Existing relationships").font(.system(size: 13, weight: .semibold))
                if existingLinks.isEmpty {
                    Text("No explicit relationships yet. Add links to preserve the context future recall and AI analysis should trust first.")
                        .font(.callout).foregroundStyle(ESTheme.muted)
                } else {
                    ForEach(existingLinks) { link in relationshipRow(link) }
                }
            }
            .padding(14).panelBackground()
        }
    }

    @ViewBuilder
    private func relationshipRow(_ link: WorkGraphLink) -> some View {
        if let otherRef = link.otherNode(than: subject) {
            let other = catalog.first { $0.ref == otherRef }
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: otherRef.kind.symbol).foregroundStyle(ESTheme.gold).frame(width: 22)
                VStack(alignment: .leading, spacing: 3) {
                    Text(other?.title ?? "Missing \(otherRef.kind.rawValue) node").font(.system(size: 13, weight: .semibold))
                    Text(directionText(link)).font(.caption).foregroundStyle(ESTheme.muted)
                    if !link.note.isEmpty { Text(link.note).font(.caption).foregroundStyle(.white.opacity(0.82)) }
                }
                Spacer()
                Button(role: .destructive) { graphStore.deleteLink(link.id) } label: { Image(systemName: "trash") }.buttonStyle(.plain)
            }
            .padding(.vertical, 6)
            Divider().overlay(ESTheme.border)
        }
    }

    private func directionText(_ link: WorkGraphLink) -> String {
        if link.source == subject { return "\(link.relationship.rawValue) → \(link.target.kind.rawValue)" }
        return "\(link.source.kind.rawValue) → \(link.relationship.rawValue) → this \(subject.kind.rawValue.lowercased())"
    }

    private func addRelationship() {
        guard let target else { return }
        _ = graphStore.createLink(source: subject, target: target, relationship: relationship, note: note)
        note = ""
    }

    private func createEntityAndLink() {
        guard let entity = graphStore.createEntity(kind: entityKind, name: entityName, notes: entityNotes) else { return }
        _ = graphStore.createLink(source: subject, target: entity.nodeRef, relationship: relationship, note: note)
        target = entity.nodeRef
        entityName = ""
        entityNotes = ""
        note = ""
    }
}
