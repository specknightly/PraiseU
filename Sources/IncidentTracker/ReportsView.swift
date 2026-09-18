import SwiftUI

struct ReportsView: View {
    @EnvironmentObject private var store: IncidentStore
    let searchText: String

    private var incidents: [IncidentRecord] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return store.incidents }
        return store.incidents.filter {
            [$0.title, $0.category, $0.tagsText, $0.observedFacts, $0.locationOrSystem, $0.peopleInvolved]
                .joined(separator: " ").lowercased().contains(needle)
        }
    }

    private var categoryCounts: [(String, Int)] {
        Dictionary(grouping: incidents, by: \.category)
            .map { ($0.key, $0.value.count) }
            .sorted { lhs, rhs in lhs.1 == rhs.1 ? lhs.0 < rhs.0 : lhs.1 > rhs.1 }
    }

    private var systemPatterns: [(String, Int)] {
        let normalized = incidents
            .filter { !$0.locationOrSystem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return Dictionary(grouping: normalized, by: { $0.locationOrSystem.trimmingCharacters(in: .whitespacesAndNewlines) })
            .map { ($0.key, $0.value.count) }
            .filter { $0.1 >= 2 }
            .sorted { $0.1 > $1.1 }
    }

    private var unresolvedFollowUps: [IncidentRecord] {
        incidents
            .filter { [.open, .monitoring].contains($0.status) && !$0.followUp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { $0.occurredAt < $1.occurredAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Reports & Patterns")
                            .font(.system(size: 22, weight: .bold))
                        Text("A higher-level view of incident volume, recurring systems, unresolved follow-up, and documentation health.")
                            .font(.system(size: 12))
                            .foregroundStyle(ESTheme.muted)
                    }
                    Spacer()
                    Button {
                        ExportService.exportReviewPacket(incidents, store: store)
                    } label: {
                        Label("Export Review Packet", systemImage: "doc.badge.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ESTheme.accent)
                }

                summaryCards

                HStack(alignment: .top, spacing: 16) {
                    categoryPanel
                    severityPanel
                }

                HStack(alignment: .top, spacing: 16) {
                    patternPanel
                    followUpPanel
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ESTheme.canvas)
    }

    private var summaryCards: some View {
        HStack(spacing: 13) {
            ReportMetric(title: "Total", value: incidents.count, symbol: "doc.text")
            ReportMetric(title: "Open / Monitoring", value: incidents.filter { [.open, .monitoring].contains($0.status) }.count, symbol: "exclamationmark.circle")
            ReportMetric(title: "Critical / High", value: incidents.filter { [.critical, .high].contains($0.severity) }.count, symbol: "exclamationmark.triangle")
            ReportMetric(title: "With Evidence", value: incidents.filter { !$0.evidence.isEmpty }.count, symbol: "paperclip")
            ReportMetric(title: "AI Enriched", value: incidents.filter { !$0.aiAnalysis.isEmpty }.count, symbol: "sparkles")
        }
    }

    private var categoryPanel: some View {
        ReportPanel(title: "Incident Categories", subtitle: "Where incidents are clustering") {
            if categoryCounts.isEmpty {
                Text("No category data yet.").foregroundStyle(ESTheme.muted)
            } else {
                VStack(spacing: 9) {
                    ForEach(categoryCounts.prefix(8), id: \.0) { category, count in
                        CountRow(label: category, count: count, maxCount: categoryCounts.first?.1 ?? 1)
                    }
                }
            }
        }
    }

    private var severityPanel: some View {
        ReportPanel(title: "Severity Distribution", subtitle: "Recorded severity, not an AI judgment") {
            VStack(spacing: 9) {
                ForEach(IncidentSeverity.allCases.reversed()) { severity in
                    let count = incidents.filter { $0.severity == severity }.count
                    CountRow(label: severity.rawValue, count: count, maxCount: max(1, incidents.count))
                }
            }
        }
    }

    private var patternPanel: some View {
        ReportPanel(title: "Recurring Location / System Signals", subtitle: "Exact repeated location or system labels") {
            if systemPatterns.isEmpty {
                Text("No repeated location/system label appears in two or more incidents yet.")
                    .font(.system(size: 12))
                    .foregroundStyle(ESTheme.muted)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(systemPatterns.prefix(8), id: \.0) { system, count in
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(ESTheme.gold)
                            Text(system).lineLimit(2)
                            Spacer()
                            Text("\(count) incidents")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(ESTheme.muted)
                        }
                    }
                }
            }
        }
    }

    private var followUpPanel: some View {
        ReportPanel(title: "Open Follow-up", subtitle: "Outstanding next steps captured on active incidents") {
            if unresolvedFollowUps.isEmpty {
                Text("No open incident currently contains a follow-up action.")
                    .font(.system(size: 12))
                    .foregroundStyle(ESTheme.muted)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(unresolvedFollowUps.prefix(8)) { incident in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(incident.title)
                                .font(.system(size: 12.5, weight: .semibold))
                            Text(incident.followUp)
                                .font(.system(size: 11.5))
                                .foregroundStyle(ESTheme.muted)
                                .lineLimit(3)
                        }
                    }
                }
            }
        }
    }
}

private struct ReportMetric: View {
    let title: String
    let value: Int
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: symbol).foregroundStyle(ESTheme.gold)
                Spacer()
            }
            Text("\(value)")
                .font(.system(size: 27, weight: .bold))
            Text(title)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(ESTheme.muted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 105, alignment: .leading)
        .panelBackground()
    }
}

private struct ReportPanel<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .bold))
                Text(subtitle).font(.system(size: 10.5)).foregroundStyle(ESTheme.muted)
            }
            content
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 245, alignment: .topLeading)
        .panelBackground()
    }
}

private struct CountRow: View {
    let label: String
    let count: Int
    let maxCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.system(size: 11.5, weight: .medium))
                Spacer()
                Text("\(count)").font(.system(size: 11, weight: .bold)).foregroundStyle(ESTheme.muted)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(ESTheme.field)
                    Capsule().fill(ESTheme.accent.opacity(0.76))
                        .frame(width: proxy.size.width * CGFloat(count) / CGFloat(max(1, maxCount)))
                }
            }
            .frame(height: 5)
        }
    }
}

struct EmptyReportState: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 38))
                .foregroundStyle(ESTheme.muted)
            Text(title).font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(ESTheme.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
