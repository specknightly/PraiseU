import SwiftUI

private enum QuickCaptureKind: String, CaseIterable, Identifiable {
    case win = "Win"
    case incident = "Incident"

    var id: String { rawValue }
    var symbol: String { self == .win ? "trophy" : "exclamationmark.triangle" }
}

struct QuickCaptureView: View {
    @EnvironmentObject private var accomplishmentStore: AccomplishmentStore
    @EnvironmentObject private var incidentStore: IncidentStore

    @State private var kind: QuickCaptureKind = .win
    @State private var title = ""
    @State private var detail = ""
    @State private var evidenceHint = ""
    @State private var saved = false

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Capture").font(.headline)
                    Text(kind == .win ? "Promotion evidence while it is fresh." : "CYA facts while they are fresh.")
                        .font(.caption)
                        .foregroundStyle(ESTheme.muted)
                }
                Spacer()
                Image(systemName: kind.symbol)
                    .foregroundStyle(ESTheme.gold)
            }

            HStack(spacing: 4) {
                ForEach(QuickCaptureKind.allCases) { item in
                    Button {
                        kind = item
                        saved = false
                    } label: {
                        Label(item.rawValue, systemImage: item.symbol)
                            .font(.system(size: 12, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(kind == item ? ESTheme.onAccent : ESTheme.muted)
                    .background(kind == item ? ESTheme.gold : ESTheme.panelRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
            }
            .padding(3)
            .background(ESTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))

            TextField(
                kind == .win ? "What did you accomplish?" : "What happened?",
                text: $title
            )
            .textFieldStyle(.roundedBorder)

            TextField(
                kind == .win
                    ? "What did you do, and what changed because of it?"
                    : "Facts only: what did you observe, hear, receive, or do?",
                text: $detail,
                axis: .vertical
            )
            .lineLimit(3...6)
            .textFieldStyle(.roundedBorder)

            TextField(
                kind == .win
                    ? "Metric, ticket, email, screenshot, or evidence to add later"
                    : "People, system, ticket/email reference, or evidence to add later",
                text: $evidenceHint,
                axis: .vertical
            )
            .lineLimit(2...4)
            .textFieldStyle(.roundedBorder)

            Text("Quick Capture saves a draft. Finish the record in WorkRecord and attach the source evidence.")
                .font(.caption2)
                .foregroundStyle(ESTheme.muted)

            HStack {
                if saved {
                    Label("Draft saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(ESTheme.gold)
                        .font(.caption)
                }
                Spacer()
                Button(kind == .win ? "Record Win" : "Document Incident") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .tint(ESTheme.accent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(
                    title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                    detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
        }
        .padding(16)
        .frame(width: 390)
    }

    private func save() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEvidence = evidenceHint.trimmingCharacters(in: .whitespacesAndNewlines)

        switch kind {
        case .win:
            var record = accomplishmentStore.createAccomplishment()
            record.title = cleanTitle.isEmpty ? "Captured win" : cleanTitle
            record.actionTaken = cleanDetail
            record.evidenceNotes = cleanEvidence
            record.category = .other
            record.tags = ["quick-capture", "promotion-evidence", "needs-review"]
            record.isDraft = true
            accomplishmentStore.save(record)

        case .incident:
            var record = incidentStore.createIncident()
            record.title = cleanTitle.isEmpty ? "Captured incident" : cleanTitle
            record.observedFacts = cleanDetail
            record.referenceNumbers = cleanEvidence
            record.tags = ["quick-capture", "cya", "needs-review"]
            record.status = .draft
            incidentStore.save(record)
        }

        title = ""
        detail = ""
        evidenceHint = ""
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saved = false }
    }
}
