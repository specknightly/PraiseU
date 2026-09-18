import SwiftUI

struct OperationalBurdenView: View {
    @EnvironmentObject private var incidentStore: IncidentStore
    @EnvironmentObject private var accomplishmentStore: AccomplishmentStore
    @EnvironmentObject private var graphStore: WorkGraphStore
    @EnvironmentObject private var burdenStore: OperationalBurdenStore

    var subject: WorkGraphNodeRef?

    @State private var selectedID: UUID?
    @State private var searchText = ""

    private var records: [OperationalBurdenRecord] {
        let base = subject.map { burdenStore.records(linkedTo: $0) } ?? burdenStore.records
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return base }
        return base.filter { record in
            [
                record.title,
                record.kind.rawValue,
                record.description,
                record.triggerOrSource,
                record.impactOnPlannedWork,
                record.measurementBasis,
                record.notes
            ]
            .joined(separator: " ")
            .lowercased()
            .contains(needle)
        }
    }

    private var selectedRecord: OperationalBurdenRecord? {
        guard let selectedID else { return nil }
        return burdenStore.record(id: selectedID)
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 10) {
                header
                TextField("Search burden records…", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                if subject == nil {
                    burdenSummary
                    kindBreakdown
                }

                List(records, selection: $selectedID) { record in
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: record.kind.symbol)
                            .foregroundStyle(record.evidenceBasis == .measured ? ESTheme.gold : ESTheme.accent)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(record.title).lineLimit(1)
                                Spacer()
                                Text(record.evidenceBasis.rawValue.uppercased())
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(ESTheme.muted)
                            }
                            Text("\(record.kind.rawValue) · \(record.date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption).foregroundStyle(ESTheme.muted)
                            Text(record.timeSummary)
                                .font(.caption2).foregroundStyle(ESTheme.muted)
                        }
                    }
                    .tag(record.id)
                }
                .scrollContentBackground(.hidden)
            }
            .padding(14)
            .frame(width: subject == nil ? 420 : 360)
            .background(ESTheme.sidebar)

            Divider().overlay(ESTheme.border)

            ScrollView {
                if let selectedRecord {
                    OperationalBurdenRecordEditor(record: selectedRecord)
                        .id(selectedRecord.id)
                        .padding(18)
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "gauge.with.dots.needle.50percent")
                            .font(.system(size: 50, weight: .light))
                            .foregroundStyle(ESTheme.gold)
                        Text("Make operational burden visible.").font(.title2.bold())
                        Text("Capture where time, interruptions, recovery effort, after-hours work, coordination, and cognitive load are actually going. Measured and estimated time stay separate so the record remains defensible.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(ESTheme.muted)
                            .frame(maxWidth: 650)
                    }
                    .frame(maxWidth: .infinity, minHeight: 540)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(ESTheme.canvas)
        .foregroundStyle(.white)
        .onAppear {
            if selectedID == nil { selectedID = records.first?.id }
        }
        .onChange(of: records.map(\.id)) { _, ids in
            if let selectedID, ids.contains(selectedID) { return }
            self.selectedID = ids.first
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(subject == nil ? "Operational Burden Intelligence" : "Burden Linked to This Record")
                    .font(.system(size: 18, weight: .bold))
                Text("Measure consumed attention without confusing workload with performance or personal worth.")
                    .font(.caption).foregroundStyle(ESTheme.muted)
            }
            Spacer()
            Button {
                let record = burdenStore.create(sourceRecord: subject)
                selectedID = record.id
            } label: {
                Label("New Burden", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(ESTheme.accent)
        }
    }

    private var burdenSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CAPTURED BURDEN").font(.system(size: 9, weight: .bold)).foregroundStyle(ESTheme.muted)
            Text("Measured: \(formatHours(burdenStore.measuredBurdenMinutes))")
                .font(.caption).foregroundStyle(ESTheme.gold)
            Text("Estimated: \(formatHours(burdenStore.estimatedBurdenMinutes))")
                .font(.caption).foregroundStyle(ESTheme.muted)
            Text("After-hours — measured \(formatHours(burdenStore.measuredAfterHoursMinutes)); estimated \(formatHours(burdenStore.estimatedAfterHoursMinutes))")
                .font(.caption2).foregroundStyle(ESTheme.muted)
            Text("\(burdenStore.totalInterruptions) interruptions · \(burdenStore.totalContextSwitches) context switches")
                .font(.caption2).foregroundStyle(ESTheme.muted)
            Text(String(format: "Average self-reported load: cognitive %.1f/5 · coordination %.1f/5", burdenStore.averageCognitiveLoad, burdenStore.averageCoordinationLoad))
                .font(.caption2).foregroundStyle(ESTheme.muted)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ESTheme.panelRaised)
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private var kindBreakdown: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("WHERE THE BURDEN GOES").font(.system(size: 9, weight: .bold)).foregroundStyle(ESTheme.muted)
            ForEach(burdenStore.kindSummaries.prefix(5)) { summary in
                HStack {
                    Image(systemName: summary.kind.symbol).frame(width: 18)
                    Text(summary.kind.rawValue).lineLimit(1)
                    Spacer()
                    Text(formatHours(summary.totalMinutes))
                        .monospacedDigit()
                        .foregroundStyle(ESTheme.muted)
                }
                .font(.caption)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ESTheme.panelRaised)
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private func formatHours(_ minutes: Int) -> String {
        String(format: "%.1f hrs", Double(minutes) / 60.0)
    }
}

private struct OperationalBurdenRecordEditor: View {
    @EnvironmentObject private var incidentStore: IncidentStore
    @EnvironmentObject private var accomplishmentStore: AccomplishmentStore
    @EnvironmentObject private var graphStore: WorkGraphStore
    @EnvironmentObject private var burdenStore: OperationalBurdenStore

    let record: OperationalBurdenRecord

    @State private var draft: OperationalBurdenRecord
    @State private var selectedLink: WorkGraphNodeRef?

    init(record: OperationalBurdenRecord) {
        self.record = record
        _draft = State(initialValue: record)
    }

    private var catalog: [WorkGraphCatalogNode] {
        WorkGraphCatalog.nodes(
            incidents: incidentStore,
            accomplishments: accomplishmentStore,
            graph: graphStore
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Image(systemName: draft.kind.symbol)
                    .font(.system(size: 28))
                    .foregroundStyle(ESTheme.gold)

                TextField("Operational burden title", text: $draft.title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 21, weight: .bold))

                Spacer()

                Button(role: .destructive) {
                    burdenStore.delete(draft.id)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)

                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(ESTheme.accent)
            }

            HStack(spacing: 12) {
                burdenBox("Date") {
                    DatePicker("", selection: $draft.date).labelsHidden()
                }
                burdenBox("Burden Type") {
                    Picker("", selection: $draft.kind) {
                        ForEach(OperationalBurdenKind.allCases) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    .labelsHidden()
                }
                burdenBox("Time Basis") {
                    Picker("", selection: $draft.evidenceBasis) {
                        ForEach(OperationalBurdenEvidenceBasis.allCases) { basis in
                            Text(basis.rawValue).tag(basis)
                        }
                    }
                    .labelsHidden()
                }
            }

            Text(draft.evidenceBasis.explanation)
                .font(.caption)
                .foregroundStyle(draft.evidenceBasis == .measured ? ESTheme.gold : ESTheme.muted)

            burdenArea(
                "What Consumed the Attention",
                "Describe the work itself without judging whether the person performing it was productive or capable.",
                $draft.description,
                95
            )

            burdenArea(
                "Trigger / Source",
                "What caused the burden: alert, user request, failing system, meeting, vendor, unclear ownership, repeated follow-up, interruption, or another source?",
                $draft.triggerOrSource,
                80
            )

            burdenArea(
                "Impact on Planned Work",
                "What planned work was delayed, fragmented, rescheduled, or forced into after-hours time? Keep observed impact separate from speculation.",
                $draft.impactOnPlannedWork,
                90
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Operational Cost").font(.system(size: 13, weight: .semibold))
                HStack(spacing: 12) {
                    burdenNumberBox("Active Minutes", value: $draft.durationMinutes)
                    burdenNumberBox("Recovery Minutes", value: $draft.recoveryMinutes)
                    burdenNumberBox("After-Hours Minutes", value: $draft.afterHoursMinutes)
                }
                HStack(spacing: 12) {
                    burdenNumberBox("Interruptions", value: $draft.interruptionCount)
                    burdenNumberBox("Context Switches", value: $draft.contextSwitchCount)
                    burdenBox("Captured Total") {
                        Text(String(format: "%.1f hrs", Double(draft.totalBurdenMinutes) / 60.0))
                            .monospacedDigit()
                    }
                }
                Text("After-hours minutes are treated as a subset of active minutes and are never added a second time to total burden.")
                    .font(.caption)
                    .foregroundStyle(ESTheme.muted)
            }
            .padding(14)
            .panelBackground()

            VStack(alignment: .leading, spacing: 10) {
                Text("Self-Reported Load").font(.system(size: 13, weight: .semibold))
                Text("These scales describe how demanding the work felt to coordinate and hold in working context. They are not medical, diagnostic, or objective productivity measures.")
                    .font(.caption)
                    .foregroundStyle(ESTheme.muted)

                HStack(spacing: 18) {
                    VStack(alignment: .leading) {
                        Text("Cognitive load: \(draft.cognitiveLoad)/5").font(.caption)
                        Slider(
                            value: Binding(
                                get: { Double(draft.cognitiveLoad) },
                                set: { draft.cognitiveLoad = Int($0.rounded()) }
                            ),
                            in: 1...5,
                            step: 1
                        )
                    }

                    VStack(alignment: .leading) {
                        Text("Coordination load: \(draft.coordinationLoad)/5").font(.caption)
                        Slider(
                            value: Binding(
                                get: { Double(draft.coordinationLoad) },
                                set: { draft.coordinationLoad = Int($0.rounded()) }
                            ),
                            in: 0...5,
                            step: 1
                        )
                    }
                }
            }
            .padding(14)
            .panelBackground()

            burdenArea(
                "Measurement / Estimate Basis",
                "Timer, calendar duration, ticket timestamps, log timestamps, meeting duration, or the assumptions used for an estimate.",
                $draft.measurementBasis,
                80
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Linked Work Context").font(.system(size: 13, weight: .semibold))

                if let source = draft.sourceRecord {
                    linkedNodeLabel("Source", source)
                }

                ForEach(draft.linkedNodes, id: \.stableKey) { ref in
                    HStack {
                        linkedNodeLabel("Linked", ref)
                        Spacer()
                        Button(role: .destructive) {
                            draft.linkedNodes.removeAll { $0 == ref }
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack {
                    Picker("Add Link", selection: $selectedLink) {
                        Text("Choose incident, accomplishment, evidence, person, system, or project…")
                            .tag(Optional<WorkGraphNodeRef>.none)

                        ForEach(catalog.filter {
                            $0.ref != draft.sourceRecord && !draft.linkedNodes.contains($0.ref)
                        }) { node in
                            Text("\(node.kind.rawValue): \(node.title)")
                                .tag(Optional(node.ref))
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
            .padding(14)
            .panelBackground()

            burdenArea(
                "Notes",
                "Supporting context, follow-up, or caveats that should travel with this burden record.",
                $draft.notes,
                95
            )

            HStack {
                Text("Last modified: \(draft.modifiedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(ESTheme.muted)
                Spacer()
                Button("Revert") {
                    if let saved = burdenStore.record(id: draft.id) { draft = saved }
                }
                Button("Save Changes") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(ESTheme.accent)
            }
        }
    }

    private func save() {
        burdenStore.save(draft)
        if let saved = burdenStore.record(id: draft.id) { draft = saved }
    }

    @ViewBuilder
    private func burdenBox<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(ESTheme.muted)
            content()
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(ESTheme.field)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))
    }

    private func burdenNumberBox(_ title: String, value: Binding<Int?>) -> some View {
        burdenBox(title) {
            TextField("Optional", value: value, format: .number)
                .textFieldStyle(.plain)
        }
    }

    private func burdenArea(
        _ title: String,
        _ help: String,
        _ text: Binding<String>,
        _ height: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 13, weight: .semibold))
            Text(help).font(.caption).foregroundStyle(ESTheme.muted)
            TextEditor(text: text)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: height)
                .background(ESTheme.field)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))
        }
        .padding(14)
        .panelBackground()
    }

    @ViewBuilder
    private func linkedNodeLabel(_ prefix: String, _ ref: WorkGraphNodeRef) -> some View {
        let node = catalog.first { $0.ref == ref }
        Label(
            "\(prefix): \(node?.title ?? "Missing \(ref.kind.rawValue)")",
            systemImage: ref.kind.symbol
        )
        .font(.caption)
        .foregroundStyle(.white.opacity(0.85))
    }
}
