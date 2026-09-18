import AppKit
import SwiftUI

struct IncidentEditorView: View {
    @EnvironmentObject private var store: IncidentStore
    @State private var draft: IncidentRecord
    @State private var tab: DetailTab = .details
    @State private var showDeleteConfirmation = false

    init(incident: IncidentRecord) {
        _draft = State(initialValue: incident)
    }

    private var liveEvidenceCount: Int {
        store.incident(id: draft.id)?.evidence.count ?? draft.evidence.count
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    header
                    metadata
                    tabs

                    Group {
                        switch tab {
                        case .details:
                            detailsTab
                        case .evidence:
                            EvidenceTabView(incidentID: draft.id)
                        case .ai:
                            IncidentAIView(draft: $draft)
                        case .recall:
                            ContextualRecallView(subject: WorkGraphNodeRef(kind: .incident, nodeID: draft.id))
                        case .prevention:
                            PreventionLedgerView(subject: WorkGraphNodeRef(kind: .incident, nodeID: draft.id))
                                .frame(minHeight: 560)
                        case .burden:
                            OperationalBurdenView(subject: WorkGraphNodeRef(kind: .incident, nodeID: draft.id))
                                .frame(minHeight: 580)
                        case .relationships:
                            RelationshipEditorView(subject: WorkGraphNodeRef(kind: .incident, nodeID: draft.id))
                        case .notes:
                            notesTab
                        }
                    }
                }
                .padding(22)
            }

            Divider().overlay(ESTheme.border)
            editorFooter
        }
        .background(ESTheme.canvas)
        .confirmationDialog(
            "Delete this incident?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Incident", role: .destructive) {
                store.delete(draft.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The incident record and its copied evidence files will be removed from the tracker.")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: draft.severity.symbol)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(ESTheme.gold)
                .frame(width: 44, height: 44)

            TextField("Incident title", text: $draft.title, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 22, weight: .bold))
                .lineLimit(1...3)

            Spacer(minLength: 20)

            Button {
                ExportService.exportIncident(mergedDraft(), store: store)
            } label: {
                Label("Export Incident", systemImage: "doc.badge.arrow.up")
            }
            .buttonStyle(.bordered)
        }
    }

    private var metadata: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MetadataBox(title: "Occurred") {
                    DatePicker("", selection: $draft.occurredAt)
                        .labelsHidden()
                }
                MetadataBox(title: "Recorded / discovered") {
                    DatePicker("", selection: $draft.discoveredAt)
                        .labelsHidden()
                }
                MetadataBox(title: "Severity") {
                    Picker("", selection: $draft.severity) {
                        ForEach(IncidentSeverity.allCases) { severity in
                            Text(severity.rawValue).tag(severity)
                        }
                    }
                    .labelsHidden()
                }
                MetadataBox(title: "Status") {
                    Picker("", selection: $draft.status) {
                        ForEach(IncidentStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .labelsHidden()
                }
            }

            HStack(spacing: 12) {
                MetadataBox(title: "Category") {
                    TextField("General", text: $draft.category)
                        .textFieldStyle(.plain)
                }
                MetadataBox(title: "Tags (comma separated)") {
                    TextField("Network, Communication, Follow-up", text: $draft.tagsText)
                        .textFieldStyle(.plain)
                }
                MetadataBox(title: "Role Scope") {
                    Picker("", selection: $draft.responsibilityScope) {
                        Text("Unclassified").tag(Optional<ResponsibilityScope>.none)
                        Text(ResponsibilityScope.core.rawValue).tag(Optional(ResponsibilityScope.core))
                        Text(ResponsibilityScope.other.rawValue).tag(Optional(ResponsibilityScope.other))
                    }
                    .labelsHidden()
                }
                Toggle("Pin this incident", isOn: $draft.isPinned)
                    .toggleStyle(.checkbox)
                    .frame(width: 150, alignment: .leading)
            }
        }
    }

    private var tabs: some View {
        HStack(spacing: 25) {
            ForEach(DetailTab.allCases) { item in
                Button {
                    tab = item
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: item.symbol)
                        Text(item == .evidence ? "Evidence (\(liveEvidenceCount))" : item.rawValue)
                    }
                    .font(.system(size: 13, weight: tab == item ? .semibold : .medium))
                    .foregroundStyle(tab == item ? ESTheme.gold : ESTheme.textPrimary.opacity(0.76))
                    .padding(.bottom, 8)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(tab == item ? ESTheme.gold : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    private var detailsTab: some View {
        VStack(spacing: 14) {
            IntegrityBanner(record: draft)
            IncidentTextArea(
                title: "Observed Facts / What Happened",
                help: "Record what was directly observed, reported, logged, or otherwise known. Keep interpretations in the next field.",
                text: $draft.observedFacts,
                minHeight: 125
            )
            IncidentTextArea(
                title: "Context / Interpretation",
                help: "Relevant context, hypotheses, statements from others, or your interpretation. Preserve uncertainty explicitly.",
                text: $draft.contextInterpretation,
                minHeight: 95
            )
            IncidentTextArea(
                title: "Impact",
                help: "Operational, user, project, service, schedule, financial, or reputational impact that actually occurred.",
                text: $draft.impact,
                minHeight: 90
            )
            IncidentTextArea(
                title: "Response / What I Did",
                help: "Troubleshooting, escalation, communication, mitigation, decisions, and other actions taken in response.",
                text: $draft.response,
                minHeight: 105
            )
            IncidentTextArea(
                title: "Resolution / Outcome",
                help: "What changed, what was restored, what remains unresolved, and the current state.",
                text: $draft.resolution,
                minHeight: 90
            )
            IncidentTextArea(
                title: "Follow-up / Next Step",
                help: "Owner, promised response, deadline, dependency, or future action that should not vanish into the organizational fog.",
                text: $draft.followUp,
                minHeight: 80
            )

            HStack(alignment: .top, spacing: 14) {
                IncidentTextArea(title: "Location / System", help: "Office, room, device, application, service, server, network, etc.", text: $draft.locationOrSystem, minHeight: 70)
                IncidentTextArea(title: "People Involved", help: "Names or roles relevant to the incident.", text: $draft.peopleInvolved, minHeight: 70)
            }
            HStack(alignment: .top, spacing: 14) {
                IncidentTextArea(title: "Witnesses / Corroboration", help: "People or independent sources that observed the same event.", text: $draft.witnesses, minHeight: 70)
                IncidentTextArea(title: "Ticket / Email / Reference Numbers", help: "Ticket IDs, case numbers, email subject, change IDs, or other durable references.", text: $draft.referenceNumbers, minHeight: 70)
            }
        }
    }

    private var notesTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Private Working Notes")
                .font(.headline)
            Text("Use this for reminders or rough thinking that does not belong in the factual narrative. Notes are included in exports, so human civilization has once again discovered that 'private' is a contextual word.")
                .font(.subheadline)
                .foregroundStyle(ESTheme.muted)
            TextEditor(text: $draft.notes)
                .font(.system(size: 14))
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(minHeight: 420)
                .background(ESTheme.field)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(ESTheme.border))
        }
        .padding(16)
        .panelBackground()
    }

    private var editorFooter: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundStyle(ESTheme.muted)
            Text("Last modified: \(draft.modifiedAt.formatted(date: .abbreviated, time: .shortened))")
                .foregroundStyle(ESTheme.muted)
                .font(.system(size: 12))

            Spacer()

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .buttonStyle(.bordered)

            Button("Revert") {
                if let latest = store.incident(id: draft.id) {
                    draft = latest
                }
            }
            .buttonStyle(.bordered)

            Button("Save Changes") {
                draft = mergedDraft()
                store.save(draft)
                if let saved = store.incident(id: draft.id) { draft = saved }
            }
            .buttonStyle(.borderedProminent)
            .tint(ESTheme.accent)
            .keyboardShortcut("s", modifiers: [.command])
        }
        .padding(.horizontal, 22)
        .frame(height: 58)
        .background(ESTheme.sidebar)
    }

    private func mergedDraft() -> IncidentRecord {
        var merged = draft
        if let live = store.incident(id: draft.id) {
            merged.evidence = live.evidence
        }
        return merged
    }
}

private struct MetadataBox<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ESTheme.muted)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .background(ESTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))
    }
}

struct IncidentTextArea: View {
    let title: String
    let help: String
    @Binding var text: String
    var minHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
            Text(help)
                .font(.system(size: 11))
                .foregroundStyle(ESTheme.muted)
            TextEditor(text: $text)
                .font(.system(size: 13.5))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: minHeight)
                .background(ESTheme.field)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .panelBackground(radius: 10)
    }
}

private struct IntegrityBanner: View {
    let record: IncidentRecord

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(ESTheme.border, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: record.completeness)
                    .stroke(ESTheme.gold, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(record.completeness * 100))%")
                    .font(.system(size: 11, weight: .bold))
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text("Documentation completeness")
                    .font(.system(size: 13, weight: .bold))
                if record.missingDocumentation.isEmpty {
                    Text("Core documentation fields are present. Completeness is not the same thing as truth; evidence and careful wording still matter.")
                        .foregroundStyle(ESTheme.muted)
                } else {
                    Text("Still useful to capture: \(record.missingDocumentation.joined(separator: ", ")).")
                        .foregroundStyle(ESTheme.muted)
                }
            }
            .font(.system(size: 11.5))
            Spacer()
        }
        .padding(14)
        .background(ESTheme.gold.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ESTheme.gold.opacity(0.24)))
    }
}
