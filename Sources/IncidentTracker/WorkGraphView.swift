import SwiftUI

struct WorkGraphView: View {
    @EnvironmentObject private var incidentStore: IncidentStore
    @EnvironmentObject private var accomplishmentStore: AccomplishmentStore
    @EnvironmentObject private var graphStore: WorkGraphStore

    @State private var searchText = ""
    @State private var selected: WorkGraphNodeRef?
    @State private var kindFilter: WorkGraphNodeKind?

    private var catalog: [WorkGraphCatalogNode] {
        WorkGraphCatalog.nodes(incidents: incidentStore, accomplishments: accomplishmentStore, graph: graphStore)
    }

    private var filtered: [WorkGraphCatalogNode] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return catalog.filter { node in
            (kindFilter == nil || node.kind == kindFilter) && (needle.isEmpty || node.searchableText.contains(needle))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Relationship-Aware Work Graph").font(.system(size: 24, weight: .bold))
                    Text("Connect wins, losses, evidence, people, systems, and projects without rewriting the source record.")
                        .font(.callout).foregroundStyle(ESTheme.muted)
                }
                Spacer()
                Text("\(graphStore.links.count) relationships").font(.caption.monospacedDigit()).foregroundStyle(ESTheme.muted)
            }.padding(20)
            Divider().overlay(ESTheme.border)

            HStack(spacing: 0) {
                VStack(spacing: 10) {
                    TextField("Search graph…", text: $searchText).textFieldStyle(.roundedBorder)
                    Picker("Type", selection: $kindFilter) {
                        Text("All node types").tag(Optional<WorkGraphNodeKind>.none)
                        ForEach(WorkGraphNodeKind.allCases) { kind in Text(kind.rawValue).tag(Optional(kind)) }
                    }
                    .pickerStyle(.menu)

                    List(filtered, selection: $selected) { node in
                        HStack(spacing: 10) {
                            Image(systemName: node.kind.symbol).foregroundStyle(ESTheme.gold).frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(node.title).lineLimit(1)
                                Text(node.subtitle).font(.caption).foregroundStyle(ESTheme.muted).lineLimit(1)
                            }
                            Spacer()
                            let count = graphStore.relationshipCount(for: node.ref)
                            if count > 0 {
                                Text("\(count)").font(.caption.monospacedDigit()).foregroundStyle(ESTheme.muted)
                            }
                        }
                        .tag(node.ref)
                    }
                    .scrollContentBackground(.hidden)
                }
                .padding(14).frame(width: 370).background(ESTheme.sidebar)

                Divider().overlay(ESTheme.border)

                ScrollView {
                    if let selected {
                        RelationshipEditorView(subject: selected).padding(20)
                    } else {
                        VStack(spacing: 15) {
                            Image(systemName: "link").font(.system(size: 48, weight: .light)).foregroundStyle(ESTheme.gold)
                            Text("Select a node to inspect its relationships").font(.title2.bold())
                            Text("Explicit links are the high-confidence layer future contextual recall and Work Intelligence will use before inferred similarity.")
                                .multilineTextAlignment(.center).foregroundStyle(ESTheme.muted).frame(maxWidth: 560)
                        }.frame(maxWidth: .infinity, minHeight: 520)
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 1050, minHeight: 720)
        .background(ESTheme.canvas).foregroundStyle(.white)
        .onAppear { repairSelection() }
        .onChange(of: searchText) { _, _ in repairSelection() }
        .onChange(of: kindFilter) { _, _ in repairSelection() }
    }

    private func repairSelection() {
        if let selected, filtered.contains(where: { $0.ref == selected }) { return }
        selected = filtered.first?.ref
    }
}
