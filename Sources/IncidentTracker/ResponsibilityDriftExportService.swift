import AppKit
import Foundation
import UniformTypeIdentifiers

enum ResponsibilityDriftExportService {
    static func markdown(report: ResponsibilityDriftReport) -> String {
        let roleTitle = report.baseline.displayTitle
        let roleDefinition = report.baseline.roleDefinition.isEmpty ? "Not supplied" : report.baseline.roleDefinition
        let expected = report.baseline.expectedAdjacentPercent
        let observed = report.outOfRoleEvidencePercent
        let delta = observed - expected

        var lines: [String] = []
        lines.append("# Responsibility Drift Evidence Packet")
        lines.append("")
        lines.append("Generated: \(Date().formatted(date: .long, time: .shortened))")
        lines.append("")
        lines.append("## Role baseline")
        lines.append("")
        lines.append("- Role title: \(roleTitle)")
        lines.append("- Baseline effective date: \(report.baseline.effectiveDate.formatted(date: .long, time: .omitted))")
        lines.append("- Expected adjacent / out-of-role allowance: \(Int(expected.rounded()))%")
        lines.append("- Role definition: \(roleDefinition)")
        lines.append("")
        lines.append("## Evidence mix")
        lines.append("")
        lines.append("- Classified records: \(report.classifiedEvidence.count)")
        lines.append("- Core-role records: \(report.coreEvidence.count)")
        lines.append("- Other / scope-drift records: \(report.outOfRoleEvidence.count)")
        lines.append("- Unclassified records: \(report.unclassifiedEvidence.count)")
        lines.append("- Other-scope share of classified records: \(String(format: "%.1f", observed))%")
        lines.append("- Difference from configured adjacent-work allowance: \(String(format: "%+.1f", delta)) percentage points")
        lines.append("")
        lines.append("> This percentage is a count of classified records, not a time-allocation measurement. Use burden-time evidence separately when discussing workload share.")
        lines.append("")
        lines.append("## Out-of-role operational burden")
        lines.append("")
        lines.append("- Measured burden: \(formatHours(report.measuredOutOfRoleBurdenMinutes))")
        lines.append("- Estimated burden: \(formatHours(report.estimatedOutOfRoleBurdenMinutes))")
        lines.append("")
        lines.append("## Higher-level out-of-role accomplishments")
        lines.append("")

        let strongest = report.advancedOutOfRoleAccomplishments.sorted {
            let left = ($0.claimStrength ?? 0, $0.evidenceCount, $0.date)
            let right = ($1.claimStrength ?? 0, $1.evidenceCount, $1.date)
            return left > right
        }
        if strongest.isEmpty {
            lines.append("No advanced/specialist/project-owner/strategic accomplishment is currently classified as Other / Scope Drift.")
        } else {
            for item in strongest.prefix(20) {
                lines.append("- **\(item.title)** — \(item.date.formatted(date: .abbreviated, time: .omitted)); \(item.workLevel?.rawValue ?? "Unclassified"); claim \(item.claimStrength ?? 0)/100; evidence files \(item.evidenceCount)")
                if !item.summary.isEmpty { lines.append("  - \(item.summary.prefix(500))") }
            }
        }

        lines.append("")
        lines.append("## Repeated systems / projects outside baseline")
        lines.append("")
        if report.ownershipSignals.isEmpty {
            lines.append("No repeated system/project ownership signal is currently supported by explicitly out-of-role records.")
        } else {
            for signal in report.ownershipSignals.prefix(20) {
                lines.append("- **\(signal.node.title)** (\(signal.node.kind.rawValue)) — \(signal.supportingRecordCount) supporting records from \(signal.firstSeen.formatted(date: .abbreviated, time: .omitted)) to \(signal.lastSeen.formatted(date: .abbreviated, time: .omitted)); measured burden \(formatHours(signal.measuredBurdenMinutes)); estimated burden \(formatHours(signal.estimatedBurdenMinutes)); sources: \(signal.evidenceKinds.map(\.rawValue).joined(separator: ", "))")
            }
        }

        lines.append("")
        lines.append("## Recent out-of-role evidence")
        lines.append("")
        for item in report.outOfRoleEvidence.prefix(30) {
            lines.append("- **\(item.date.formatted(date: .abbreviated, time: .omitted)) — \(item.kind.rawValue): \(item.title)**")
            if !item.summary.isEmpty { lines.append("  - \(item.summary.prefix(500))") }
        }

        lines.append("")
        lines.append("## Review discussion uses")
        lines.append("")
        lines.append("- Role/title alignment: compare repeated documented work to the saved role baseline.")
        lines.append("- Staffing: use measured operational burden and recurring system/project ownership evidence separately from accomplishment counts.")
        lines.append("- Compensation or promotion: emphasize higher-level accomplishments, evidence strength, responsibility duration, and repeated ownership rather than record volume alone.")
        lines.append("")
        lines.append("## Limitations")
        lines.append("")
        lines.append("- Scope labels are user classifications and should be supported by the official role description, assignment history, or other durable evidence.")
        lines.append("- Record counts are not the same as percentage of working time.")
        lines.append("- Estimated burden remains estimated.")
        lines.append("- Repeated linkage to a system/project is an ownership signal, not proof of formal accountability.")
        lines.append("- Generated AI analysis, if used, is non-evidentiary and should be checked against these source records.")

        return lines.joined(separator: "\n")
    }

    static func export(report: ResponsibilityDriftReport) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "Responsibility-Drift-Evidence.md"
        panel.title = "Export Responsibility Drift Evidence"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try markdown(report: report).data(using: .utf8)?.write(to: url, options: .atomic)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private static func formatHours(_ minutes: Int) -> String {
        String(format: "%.1f hrs", Double(minutes) / 60.0)
    }
}
