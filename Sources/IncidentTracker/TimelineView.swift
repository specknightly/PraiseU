import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var store: IncidentStore
    let searchText: String

    private var incidents: [IncidentRecord] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return store.incidents
            .filter { incident in
                needle.isEmpty || [incident.title, incident.category, incident.observedFacts, incident.locationOrSystem]
                    .joined(separator: " ").lowercased().contains(needle)
            }
            .sorted { $0.occurredAt > $1.occurredAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Incident Timeline")
                        .font(.system(size: 22, weight: .bold))
                    Text("Chronological view of what happened, how it was handled, and what followed.")
                        .font(.system(size: 12))
                        .foregroundStyle(ESTheme.muted)
                }
                Spacer()
            }
            .padding(22)

            Divider().overlay(ESTheme.border)

            if incidents.isEmpty {
                EmptyReportState(symbol: "clock", title: "No incidents in the timeline", detail: "Recorded incidents will appear here in chronological order.")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(incidents) { incident in
                            TimelineRow(incident: incident)
                        }
                    }
                    .padding(.horizontal, 34)
                    .padding(.vertical, 22)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ESTheme.canvas)
    }
}

private struct TimelineRow: View {
    let incident: IncidentRecord

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(spacing: 0) {
                Circle()
                    .fill(incident.severity == .critical || incident.severity == .high ? ESTheme.gold : ESTheme.accent)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
                Rectangle()
                    .fill(ESTheme.border)
                    .frame(width: 2)
                    .frame(minHeight: 155)
            }
            .padding(.top, 7)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(incident.occurredAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(ESTheme.gold)
                        Text(incident.title)
                            .font(.system(size: 17, weight: .bold))
                    }
                    Spacer()
                    Text(incident.status.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ESTheme.panelRaised)
                        .clipShape(Capsule())
                }

                if !incident.observedFacts.isEmpty {
                    TimelineMiniSection(label: "What happened", text: incident.observedFacts)
                }
                if !incident.response.isEmpty {
                    TimelineMiniSection(label: "Response", text: incident.response)
                }
                if !incident.resolution.isEmpty {
                    TimelineMiniSection(label: "Outcome", text: incident.resolution)
                }

                HStack(spacing: 12) {
                    Label(incident.category, systemImage: "folder")
                    if !incident.locationOrSystem.isEmpty {
                        Label(incident.locationOrSystem, systemImage: "desktopcomputer")
                    }
                    if !incident.evidence.isEmpty {
                        Label("\(incident.evidence.count) evidence", systemImage: "paperclip")
                    }
                }
                .font(.system(size: 10.5))
                .foregroundStyle(ESTheme.muted)
            }
            .padding(15)
            .panelBackground()
            .padding(.bottom, 15)
        }
    }
}

private struct TimelineMiniSection: View {
    let label: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(ESTheme.muted)
            Text(text)
                .font(.system(size: 12.5))
                .lineLimit(3)
        }
    }
}
