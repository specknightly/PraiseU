import SwiftUI

struct PreventionLedgerView: View {
    @EnvironmentObject private var incidentStore: IncidentStore
    @EnvironmentObject private var accomplishmentStore: AccomplishmentStore
    @EnvironmentObject private var graphStore: WorkGraphStore
    @EnvironmentObject private var ledgerStore: PreventionLedgerStore

    var subject: WorkGraphNodeRef?

    @State private var selectedID: UUID?
    @State private var searchText = ""

    private var records: [PreventionInterventionRecord] {
        let base = subject.map { ledgerStore.records(linkedTo: $0) } ?? ledgerStore.records
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return base }
        return base.filter {
            [$0.title, $0.type.rawValue, $0.actionTaken, $0.riskOrFailureMode, $0.expectedConsequence,
             $0.observedResult, $0.measurementBasis, $0.notes]
                .joined(separator: " ").lowercased().contains(needle)
        }
    }

    private var selectedRecord: PreventionInterventionRecord? {
        guard let selectedID else { return nil }
        return ledgerStore.record(id: selectedID)
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(subject == nil ? "Prevention & Intervention Ledger" : "Prevention Linked to This Record")
                            .font(.system(size: 18, weight: .bold))
                        Text("Record what you prevented, mitigated, detected early, hardened, automated, or made less likely to recur.")
                            .font(.caption).foregroundStyle(ESTheme.muted)
                    }
                    Spacer()
                    Button {
                        let record = ledgerStore.create(sourceRecord: subject)
                        selectedID = record.id
                    } label: {
                        Label("New Entry", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent).tint(ESTheme.accent)
                }

                TextField("Search prevention records…", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 14) {
                    Label("\(records.count) entries", systemImage: "shield.checkered")
                    if subject == nil {
                        Label("\(ledgerStore.measuredCount) measured", systemImage: "ruler")
                        Label("\(ledgerStore.quantifiedCount) quantified", systemImage: "number")
                    }
                }
                .font(.caption).foregroundStyle(ESTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)

                List(records, selection: $selectedID) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(record.title).lineLimit(1)
                            Spacer()
                            Text(record.evidenceBasis.rawValue.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(record.evidenceBasis == .measured ? ESTheme.gold : ESTheme.muted)
                        }
                        Text("\(record.type.rawValue) · \(record.date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption).foregroundStyle(ESTheme.muted)
                        Text(record.quantificationSummary)
                            .font(.caption2).foregroundStyle(ESTheme.muted).lineLimit(1)
                    }
                    .tag(record.id)
                }
                .scrollContentBackground(.hidden)
            }
            .padding(14)
            .frame(width: subject == nil ? 390 : 350)
            .background(ESTheme.sidebar)

            Divider().overlay(ESTheme.border)

            ScrollView {
                if let selectedRecord {
                    PreventionRecordEditor(record: selectedRecord)
                        .id(selectedRecord.id)
                        .padding(18)
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "shield.checkered").font(.system(size: 48, weight: .light)).foregroundStyle(ESTheme.gold)
                        Text("Invisible prevention work belongs in the record.").font(.title2.bold())
                        Text("Capture the intervention, what it was intended to prevent, what actually happened afterward, and how strong the evidence is. Do not turn a plausible avoided problem into a measured fact unless you have a basis.")
                            .multilineTextAlignment(.center).foregroundStyle(ESTheme.muted).frame(maxWidth: 620)
                    }
                    .frame(maxWidth: .infinity, minHeight: 520)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(ESTheme.canvas).foregroundStyle(.white)
        .onAppear {
            if selectedID == nil { selectedID = records.first?.id }
        }
        .onChange(of: records.map(\.id)) { _, ids in
            if let selectedID, ids.contains(selectedID) { return }
            self.selectedID = ids.first
        }
    }
}

private struct PreventionRecordEditor: View {
    @EnvironmentObject private var incidentStore: IncidentStore
    @EnvironmentObject private var accomplishmentStore: AccomplishmentStore
    @EnvironmentObject private var graphStore: WorkGraphStore
    @EnvironmentObject private var ledgerStore: PreventionLedgerStore

    let record: PreventionInterventionRecord
    @State private var draft: PreventionInterventionRecord
    @State private var selectedLink: WorkGraphNodeRef?

    init(record: PreventionInterventionRecord) {
        self.record = record
        _draft = State(initialValue: record)
    }

    private var catalog: [WorkGraphCatalogNode] {
        WorkGraphCatalog.nodes(incidents: incidentStore, accomplishments: accomplishmentStore, graph: graphStore)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Image(systemName: "shield.checkered").font(.system(size: 28)).foregroundStyle(ESTheme.gold)
                TextField("Prevention / intervention title", text: $draft.title)
                    .textFieldStyle(.plain).font(.system(size: 21, weight: .bold))
                Spacer()
                Button(role: .destructive) { ledgerStore.delete(draft.id) } label: { Image(systemName: "trash") }
                    .buttonStyle(.bordered)
                Button("Save") { ledgerStore.save(draft); if let saved = ledgerStore.record(id: draft.id) { draft = saved } }
                    .buttonStyle(.borderedProminent).tint(ESTheme.accent)
            }

            HStack(spacing: 12) {
                ledgerBox("Date") { DatePicker("", selection: $draft.date).labelsHidden() }
                ledgerBox("Intervention Type") {
                    Picker("", selection: $draft.type) {
                        ForEach(PreventionInterventionType.allCases) { Text($0.rawValue).tag($0) }
                    }.labelsHidden()
                }
                ledgerBox("Evidence Basis") {
                    Picker("", selection: $draft.evidenceBasis) {
                        ForEach(PreventionEvidenceBasis.allCases) { Text($0.rawValue).tag($0) }
                    }.labelsHidden()
                }
            }

            Text(draft.evidenceBasis.explanation)
                .font(.caption)
                .foregroundStyle(draft.evidenceBasis == .measured ? ESTheme.gold : ESTheme.muted)

            ledgerArea("Intervention / What I Did", "The preventive action, mitigation, monitoring, hardening, automation, documentation, training, or process change you performed.", $draft.actionTaken, 100)
            ledgerArea("Risk / Failure Mode Addressed", "What failure, recurrence, operational risk, or avoidable burden was this intended to reduce?", $draft.riskOrFailureMode, 90)
            ledgerArea("Expected Consequence Without Intervention", "Describe the plausible consequence conservatively. Do not state an avoided event as fact unless the evidence supports it.", $draft.expectedConsequence, 85)
            ledgerArea("Observed Result", "What actually happened after the intervention? Record observed results separately from what might have happened.", $draft.observedResult, 90)

            VStack(alignment: .leading, spacing: 10) {
                Text("Quantification").font(.system(size: 13, weight: .semibold))
                if draft.evidenceBasis == .inferred {
                    Text("Numeric avoided-impact fields are disabled for inferred claims. Change Evidence Basis to Measured or Estimated and document the basis before quantifying.")
                        .font(.caption).foregroundStyle(ESTheme.gold)
                } else {
                    HStack(spacing: 12) {
                        ledgerNumberBox("Recurrences Avoided", value: $draft.recurrenceCountAvoided)
                        ledgerDoubleBox("Hours Avoided", value: $draft.hoursAvoided)
                        ledgerNumberBox("People / Systems Protected", value: $draft.peopleOrSystemsProtected)
                    }
                }
                ledgerArea("Measurement / Estimate Basis", "Ticket counts, logs, elapsed time, before/after frequency, runbook timing, or the assumptions behind an estimate.", $draft.measurementBasis, 80)
                Text("WorkRecord deliberately does not calculate avoided dollar value. Add monetary evidence only if you have a defensible external basis.")
                    .font(.caption).foregroundStyle(ESTheme.muted)
            }
            .padding(14).panelBackground()

            VStack(alignment: .leading, spacing: 10) {
                Text("Linked Work Record Context").font(.system(size: 13, weight: .semibold))
                if let source = draft.sourceRecord {
                    linkedNodeLabel("Source", source)
                }
                ForEach(draft.linkedNodes, id: \.stableKey) { ref in
                    HStack {
                        linkedNodeLabel("Linked", ref)
                        Spacer()
                        Button(role: .destructive) { draft.linkedNodes.removeAll { $0 == ref } } label: { Image(systemName: "xmark") }
                            .buttonStyle(.plain)
                    }
                }
                HStack {
                    Picker("Add Link", selection: $selectedLink) {
                        Text("Choose incident, accomplishment, evidence, person, system, or project…").tag(Optional<WorkGraphNodeRef>.none)
                        ForEach(catalog.filter { $0.ref != draft.sourceRecord && !draft.linkedNodes.contains($0.ref) }) { node in
                            Text("\(node.kind.rawValue): \(node.title)").tag(Optional(node.ref))
                        }
                    }
                    Button("Add") {
                        if let selectedLink, !draft.linkedNodes.contains(selectedLink) {
                            draft.linkedNodes.append(selectedLink)
                            self.selectedLink = nil
                        }
                    }
                    .disabled(selectedLink == nil)
                }
            }
            .padding(14).panelBackground()

            ledgerArea("Notes", "Supporting detail, assumptions, or follow-up that does not belong in the core claim.", $draft.notes, 100)

            HStack {
                Text("Last modified: \(draft.modifiedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption).foregroundStyle(ESTheme.muted)
                Spacer()
                Button("Revert") { if let saved = ledgerStore.record(id: draft.id) { draft = saved } }
                Button("Save Changes") { ledgerStore.save(draft); if let saved = ledgerStore.record(id: draft.id) { draft = saved } }
                    .buttonStyle(.borderedProminent).tint(ESTheme.accent)
            }
        }
    }

    @ViewBuilder
    private func ledgerBox<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased()).font(.system(size: 9, weight: .bold)).foregroundStyle(ESTheme.muted)
            content()
        }
        .padding(10).frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(ESTheme.field).clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))
    }

    private func ledgerArea(_ title: String, _ help: String, _ text: Binding<String>, _ height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 13, weight: .semibold))
            Text(help).font(.caption).foregroundStyle(ESTheme.muted)
            TextEditor(text: text).scrollContentBackground(.hidden).padding(8).frame(minHeight: height)
                .background(ESTheme.field).clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))
        }
        .padding(14).panelBackground()
    }

    private func ledgerNumberBox(_ title: String, value: Binding<Int?>) -> some View {
        ledgerBox(title) { TextField("Optional", value: value, format: .number).textFieldStyle(.plain) }
    }

    private func ledgerDoubleBox(_ title: String, value: Binding<Double?>) -> some View {
        ledgerBox(title) { TextField("Optional", value: value, format: .number.precision(.fractionLength(0...1))).textFieldStyle(.plain) }
    }

    @ViewBuilder
    private func linkedNodeLabel(_ prefix: String, _ ref: WorkGraphNodeRef) -> some View {
        let node = catalog.first { $0.ref == ref }
        Label("\(prefix): \(node?.title ?? "Missing \(ref.kind.rawValue)")", systemImage: ref.kind.symbol)
            .font(.caption).foregroundStyle(.white.opacity(0.85))
    }
}
