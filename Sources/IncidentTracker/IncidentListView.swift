import SwiftUI

struct IncidentListView: View {
    let incidents: [IncidentRecord]
    let selection: SidebarSelection
    @Binding var selectedIncidentID: UUID?
    @Binding var sort: IncidentSort

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Picker("Sort", selection: $sort) {
                    ForEach(IncidentSort.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .labelsHidden()
                .frame(width: 155)
            }
            .padding(.horizontal, 18)
            .frame(height: 66)

            if incidents.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 34))
                        .foregroundStyle(ESTheme.muted)
                    Text("No matching incidents")
                        .font(.headline)
                    Text("The absence of records is either excellent news or merely under-documentation. The app refuses to guess which.")
                        .font(.subheadline)
                        .foregroundStyle(ESTheme.muted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 5) {
                        ForEach(incidents) { incident in
                            IncidentListCard(
                                incident: incident,
                                selected: selectedIncidentID == incident.id
                            ) {
                                selectedIncidentID = incident.id
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 16)
                }
            }
        }
        .background(ESTheme.canvas)
    }

    private var title: String {
        switch selection {
        case .all: return "All Incidents"
        case .thisYear: return "This Year"
        case .pinned: return "Pinned"
        case .drafts: return "Drafts"
        case .open: return "Open / Monitoring"
        case .resolved: return "Resolved / Closed"
        case .category(let value): return value
        case .tag(let value): return "#\(value)"
        case .timeline: return "Timeline"
        case .reports: return "Reports"
        }
    }
}

private struct IncidentListCard: View {
    let incident: IncidentRecord
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: incident.severity.symbol)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(incident.severity == .critical || incident.severity == .high ? ESTheme.gold : ESTheme.textPrimary.opacity(0.82))
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .top) {
                        Text(incident.title)
                            .font(.system(size: 14, weight: .semibold))
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                        Spacer(minLength: 6)
                        if incident.isPinned {
                            Image(systemName: "pin.fill")
                                .foregroundStyle(ESTheme.gold)
                        }
                    }

                    HStack(spacing: 7) {
                        Text(incident.occurredAt.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(selected ? ESTheme.textPrimary.opacity(0.82) : ESTheme.muted)
                        Text("•")
                            .foregroundStyle(selected ? ESTheme.goldSoft.opacity(0.60) : ESTheme.muted)
                        Text(incident.status.rawValue)
                            .foregroundStyle(selected ? ESTheme.textPrimary.opacity(0.82) : ESTheme.muted)
                    }
                    .font(.system(size: 11))

                    HStack(spacing: 6) {
                        TagPill(text: incident.category, selected: selected)
                        ForEach(Array(incident.tags.prefix(1)), id: \.self) { tag in
                            TagPill(text: tag, selected: selected)
                        }
                        if incident.evidence.count > 0 {
                            Label("\(incident.evidence.count)", systemImage: "paperclip")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(selected ? ESTheme.goldSoft : ESTheme.muted)
                        }
                    }
                }
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? ESTheme.selection : ESTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? ESTheme.borderStrong : ESTheme.border))
        }
        .buttonStyle(.plain)
    }
}

private struct TagPill: View {
    let text: String
    let selected: Bool
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(selected ? ESTheme.gold.opacity(0.15) : ESTheme.panelRaised)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
