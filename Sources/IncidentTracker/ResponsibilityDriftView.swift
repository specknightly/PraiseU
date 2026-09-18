import AppKit
import SwiftUI

struct ResponsibilityDriftView: View {
    @EnvironmentObject private var incidentStore: IncidentStore
    @EnvironmentObject private var accomplishmentStore: AccomplishmentStore
    @EnvironmentObject private var graphStore: WorkGraphStore
    @EnvironmentObject private var preventionStore: PreventionLedgerStore
    @EnvironmentObject private var burdenStore: OperationalBurdenStore
    @EnvironmentObject private var driftStore: ResponsibilityDriftStore

    @AppStorage("roleTitle") private var roleTitle = ""
    @AppStorage("coreRoleDefinition") private var coreRoleDefinition = "Password resets, routine account access, basic desktop support, and other duties explicitly assigned to my primary IT support role."
    @AppStorage("expectedOtherPercent") private var expectedOtherPercent = 10.0

    @State private var intelligence = ""
    @State private var isAnalyzing = false
    @State private var analysisError: String?

    private var report: ResponsibilityDriftReport {
        ResponsibilityDriftEngine.buildReport(
            incidents: incidentStore,
            accomplishments: accomplishmentStore,
            prevention: preventionStore,
            burden: burdenStore,
            graph: graphStore,
            drift: driftStore,
            fallbackRoleTitle: roleTitle,
            fallbackRoleDefinition: coreRoleDefinition,
            fallbackExpectedAdjacentPercent: expectedOtherPercent
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                summaryGrid

                if !report.unclassifiedEvidence.isEmpty {
                    unclassifiedBanner
                }

                baselineHistory
                driftTimeline
                ownershipPanel
                evidencePanel

                if let analysisError {
                    Label(analysisError, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(ESTheme.gold)
                        .padding(12)
                        .panelBackground()
                }

                if !intelligence.isEmpty {
                    intelligencePanel
                }
            }
            .padding(22)
        }
        .frame(minWidth: 1120, minHeight: 780)
        .background(ESTheme.canvas)
        .foregroundStyle(.white)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(ESTheme.gold)

            VStack(alignment: .leading, spacing: 4) {
                Text("Responsibility Drift Observatory")
                    .font(.system(size: 25, weight: .bold))
                Text("Compare documented work against dated role baselines and show how responsibilities changed over time.")
                    .font(.callout)
                    .foregroundStyle(ESTheme.muted)
            }

            Spacer()

            Button {
                _ = driftStore.createBaseline(
                    roleTitle: roleTitle,
                    roleDefinition: coreRoleDefinition,
                    expectedAdjacentPercent: expectedOtherPercent
                )
            } label: {
                Label("Snapshot Baseline", systemImage: "camera")
            }
            .buttonStyle(.bordered)

            Button {
                ResponsibilityDriftExportService.export(report: report)
            } label: {
                Label("Export Evidence", systemImage: "doc.badge.arrow.up")
            }
            .buttonStyle(.bordered)

            Button {
                analyze()
            } label: {
                Label(isAnalyzing ? "Analyzing…" : "Build Review Brief", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .tint(ESTheme.accent)
            .disabled(isAnalyzing || report.classifiedEvidence.count < 2 || !AccomplishmentAIService.isAvailable)
        }
    }

    private var summaryGrid: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "CURRENT BASELINE",
                value: report.baseline.displayTitle,
                detail: report.usesFallbackBaseline
                    ? "Current Settings · not yet a dated snapshot"
                    : "Effective \(report.baseline.effectiveDate.formatted(date: .abbreviated, time: .omitted))"
            )

            summaryCard(
                title: "CLASSIFIED EVIDENCE",
                value: "\(report.classifiedEvidence.count)",
                detail: "\(report.coreEvidence.count) core · \(report.outOfRoleEvidence.count) other"
            )

            summaryCard(
                title: "OTHER-SCOPE EVIDENCE MIX",
                value: String(format: "%.1f%%", report.outOfRoleEvidencePercent),
                detail: "Configured adjacent-work allowance: \(Int(report.baseline.expectedAdjacentPercent.rounded()))%"
            )

            summaryCard(
                title: "OUT-OF-ROLE BURDEN",
                value: formatHours(report.measuredOutOfRoleBurdenMinutes),
                detail: "Measured · \(formatHours(report.estimatedOutOfRoleBurdenMinutes)) estimated"
            )

            summaryCard(
                title: "OWNERSHIP SIGNALS",
                value: "\(report.ownershipSignals.count)",
                detail: "Systems/projects with explicit out-of-role support"
            )
        }
    }

    private var unclassifiedBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(ESTheme.gold)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(report.unclassifiedEvidence.count) record\(report.unclassifiedEvidence.count == 1 ? "" : "s") remain unclassified")
                    .font(.system(size: 13, weight: .semibold))
                Text("The observatory excludes unclassified records from the scope percentage. Classify incidents, accomplishments, prevention entries, and burden records explicitly to strengthen the comparison.")
                    .font(.caption)
                    .foregroundStyle(ESTheme.muted)
            }
            Spacer()
        }
        .padding(14)
        .background(ESTheme.gold.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ESTheme.gold.opacity(0.25)))
    }

    private var baselineHistory: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Role Baseline History").font(.headline)

            if driftStore.baselines.isEmpty {
                Text("No dated snapshot has been saved yet. The observatory is using the current Settings baseline as a fallback.")
                    .font(.callout)
                    .foregroundStyle(ESTheme.muted)
            } else {
                ForEach(driftStore.baselines.prefix(8)) { baseline in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(ESTheme.gold)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(baseline.displayTitle).font(.system(size: 13, weight: .semibold))
                            Text("Effective \(baseline.effectiveDate.formatted(date: .long, time: .omitted)) · expected adjacent work \(Int(baseline.expectedAdjacentPercent.rounded()))%")
                                .font(.caption)
                                .foregroundStyle(ESTheme.muted)
                            if !baseline.roleDefinition.isEmpty {
                                Text(baseline.roleDefinition)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.82))
                                    .lineLimit(2)
                            }
                        }

                        Spacer()

                        Button(role: .destructive) {
                            driftStore.delete(baseline.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(14)
        .panelBackground()
    }

    private var driftTimeline: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Drift Over Time").font(.headline)
                Spacer()
                Text("Evidence mix, not time share")
                    .font(.caption)
                    .foregroundStyle(ESTheme.muted)
            }

            let periods = Array(report.periods.suffix(18).reversed())
            if periods.isEmpty {
                Text("No dated scope evidence yet.")
                    .font(.callout)
                    .foregroundStyle(ESTheme.muted)
            } else {
                ForEach(periods) { period in
                    HStack(spacing: 12) {
                        Text(period.month.formatted(.dateTime.year().month(.abbreviated)))
                            .font(.caption.monospacedDigit())
                            .frame(width: 90, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(period.otherCount) other / \(period.classifiedCount) classified")
                                .font(.system(size: 12, weight: .semibold))
                            Text("\(period.unclassifiedCount) unclassified")
                                .font(.caption2)
                                .foregroundStyle(ESTheme.muted)
                        }
                        .frame(width: 150, alignment: .leading)

                        ProgressView(value: min(100, max(0, period.otherEvidencePercent)), total: 100)
                            .frame(maxWidth: .infinity)

                        Text(String(format: "%.1f%%", period.otherEvidencePercent))
                            .font(.caption.monospacedDigit())
                            .frame(width: 58, alignment: .trailing)

                        Text("expected \(Int(period.expectedAdjacentPercent.rounded()))%")
                            .font(.caption)
                            .foregroundStyle(ESTheme.muted)
                            .frame(width: 92, alignment: .trailing)

                        Text(String(format: "%+.1f pp", period.deltaFromExpectedPoints))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(period.deltaFromExpectedPoints > 0 ? ESTheme.gold : ESTheme.muted)
                            .frame(width: 70, alignment: .trailing)

                        Text("\(formatHours(period.measuredOtherBurdenMinutes)) M / \(formatHours(period.estimatedOtherBurdenMinutes)) E")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(ESTheme.muted)
                            .frame(width: 120, alignment: .trailing)
                    }
                    Divider().overlay(ESTheme.border)
                }
            }

            Text("The percentage above is the share of explicitly classified records marked Other / Scope Drift. It does not claim that the same percentage of working hours was outside the role.")
                .font(.caption)
                .foregroundStyle(ESTheme.muted)
        }
        .padding(14)
        .panelBackground()
    }

    private var ownershipPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("De Facto Ownership Signals").font(.headline)
            Text("Repeated out-of-role links to systems or projects. These are evidence signals, not proof of formal accountability.")
                .font(.caption)
                .foregroundStyle(ESTheme.muted)

            if report.ownershipSignals.isEmpty {
                Text("No repeated system/project scope signal is supported yet.")
                    .font(.callout)
                    .foregroundStyle(ESTheme.muted)
            } else {
                ForEach(report.ownershipSignals.prefix(12)) { signal in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: signal.node.kind.symbol)
                            .foregroundStyle(ESTheme.gold)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(signal.node.title).font(.system(size: 13, weight: .semibold))
                            Text("\(signal.supportingRecordCount) supporting record\(signal.supportingRecordCount == 1 ? "" : "s") · \(signal.firstSeen.formatted(date: .abbreviated, time: .omitted)) → \(signal.lastSeen.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(ESTheme.muted)
                            Text("Sources: \(signal.evidenceKinds.map(\.rawValue).joined(separator: ", ")) · burden \(formatHours(signal.measuredBurdenMinutes)) measured / \(formatHours(signal.estimatedBurdenMinutes)) estimated")
                                .font(.caption2)
                                .foregroundStyle(ESTheme.muted)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                    Divider().overlay(ESTheme.border)
                }
            }
        }
        .padding(14)
        .panelBackground()
    }

    private var evidencePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Other / Scope Drift Evidence").font(.headline)
                Spacer()
                Text("\(report.advancedOutOfRoleAccomplishments.count) higher-level accomplishment\(report.advancedOutOfRoleAccomplishments.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(ESTheme.muted)
            }

            if report.outOfRoleEvidence.isEmpty {
                Text("No records are explicitly classified as Other / Scope Drift.")
                    .font(.callout)
                    .foregroundStyle(ESTheme.muted)
            } else {
                ForEach(report.outOfRoleEvidence.prefix(30)) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: item.kind.symbol)
                            .foregroundStyle(ESTheme.gold)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(item.title).font(.system(size: 13, weight: .semibold))
                                if let level = item.workLevel, level != .unclassified {
                                    Text(level.rawValue.uppercased())
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(ESTheme.gold)
                                }
                            }
                            Text("\(item.kind.rawValue) · \(item.date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(ESTheme.muted)
                            if !item.summary.isEmpty {
                                Text(item.summary)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .lineLimit(3)
                            }
                            if item.measuredBurdenMinutes > 0 || item.estimatedBurdenMinutes > 0 {
                                Text("Burden: \(formatHours(item.measuredBurdenMinutes)) measured / \(formatHours(item.estimatedBurdenMinutes)) estimated")
                                    .font(.caption2)
                                    .foregroundStyle(ESTheme.muted)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    Divider().overlay(ESTheme.border)
                }
            }
        }
        .padding(14)
        .panelBackground()
    }

    private var intelligencePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Responsibility Drift Review Brief").font(.headline)
                Spacer()
                Text("On-device · non-evidentiary")
                    .font(.caption)
                    .foregroundStyle(ESTheme.muted)
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(intelligence, forType: .string)
                }
                Button("Close") { intelligence = "" }
            }

            TextEditor(text: $intelligence)
                .font(.system(size: 13))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 430)
                .background(ESTheme.field)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))
        }
        .padding(14)
        .panelBackground()
    }

    private func summaryCard(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 9, weight: .bold)).foregroundStyle(ESTheme.muted)
            Text(value).font(.system(size: 19, weight: .bold)).lineLimit(1)
            Text(detail).font(.caption2).foregroundStyle(ESTheme.muted).lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .background(ESTheme.panelRaised)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))
    }

    private func analyze() {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        analysisError = nil

        Task {
            do {
                let result = try await ResponsibilityDriftAIService.analyze(report: report)
                await MainActor.run {
                    intelligence = result
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    analysisError = error.localizedDescription
                    isAnalyzing = false
                }
            }
        }
    }

    private func formatHours(_ minutes: Int) -> String {
        String(format: "%.1f hrs", Double(minutes) / 60.0)
    }
}
