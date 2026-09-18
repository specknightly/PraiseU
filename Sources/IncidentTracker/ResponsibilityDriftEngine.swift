import Foundation

struct ResponsibilityDriftEvidenceItem: Identifiable, Hashable {
    let id: String
    let date: Date
    let kind: ScopeEvidenceKind
    let title: String
    let scope: ResponsibilityScope
    let summary: String
    let workLevel: WorkLevel?
    let claimStrength: Int?
    let evidenceCount: Int
    let measuredBurdenMinutes: Int
    let estimatedBurdenMinutes: Int
    let nodeRef: WorkGraphNodeRef?

    var isClassified: Bool { scope != .unclassified }
    var isOutOfRole: Bool { scope == .other }
}

struct ResponsibilityDriftPeriod: Identifiable, Hashable {
    let month: Date
    let coreCount: Int
    let otherCount: Int
    let unclassifiedCount: Int
    let measuredOtherBurdenMinutes: Int
    let estimatedOtherBurdenMinutes: Int
    let expectedAdjacentPercent: Double

    var id: Date { month }
    var classifiedCount: Int { coreCount + otherCount }
    var otherEvidencePercent: Double {
        guard classifiedCount > 0 else { return 0 }
        return Double(otherCount) / Double(classifiedCount) * 100
    }
    var deltaFromExpectedPoints: Double { otherEvidencePercent - expectedAdjacentPercent }
}

struct ResponsibilityOwnershipSignal: Identifiable, Hashable {
    let node: WorkGraphCatalogNode
    let supportingRecordCount: Int
    let evidenceKinds: [ScopeEvidenceKind]
    let firstSeen: Date
    let lastSeen: Date
    let measuredBurdenMinutes: Int
    let estimatedBurdenMinutes: Int

    var id: String { node.id }
}

struct ResponsibilityDriftReport {
    let baseline: RoleBaselineSnapshot
    let usesFallbackBaseline: Bool
    let evidence: [ResponsibilityDriftEvidenceItem]
    let periods: [ResponsibilityDriftPeriod]
    let ownershipSignals: [ResponsibilityOwnershipSignal]

    var classifiedEvidence: [ResponsibilityDriftEvidenceItem] { evidence.filter(\.isClassified) }
    var outOfRoleEvidence: [ResponsibilityDriftEvidenceItem] { evidence.filter(\.isOutOfRole) }
    var coreEvidence: [ResponsibilityDriftEvidenceItem] { evidence.filter { $0.scope == .core } }
    var unclassifiedEvidence: [ResponsibilityDriftEvidenceItem] { evidence.filter { $0.scope == .unclassified } }

    var outOfRoleEvidencePercent: Double {
        guard !classifiedEvidence.isEmpty else { return 0 }
        return Double(outOfRoleEvidence.count) / Double(classifiedEvidence.count) * 100
    }

    var measuredOutOfRoleBurdenMinutes: Int {
        outOfRoleEvidence.reduce(0) { $0 + $1.measuredBurdenMinutes }
    }

    var estimatedOutOfRoleBurdenMinutes: Int {
        outOfRoleEvidence.reduce(0) { $0 + $1.estimatedBurdenMinutes }
    }

    var advancedOutOfRoleAccomplishments: [ResponsibilityDriftEvidenceItem] {
        outOfRoleEvidence.filter {
            guard let level = $0.workLevel else { return false }
            return [.advanced, .specialist, .projectOwner, .strategic].contains(level)
        }
    }
}

@MainActor
enum ResponsibilityDriftEngine {
    static func buildReport(
        incidents: IncidentStore,
        accomplishments: AccomplishmentStore,
        prevention: PreventionLedgerStore,
        burden: OperationalBurdenStore,
        graph: WorkGraphStore,
        drift: ResponsibilityDriftStore,
        fallbackRoleTitle: String,
        fallbackRoleDefinition: String,
        fallbackExpectedAdjacentPercent: Double
    ) -> ResponsibilityDriftReport {
        let fallback = RoleBaselineSnapshot(
            effectiveDate: Date(),
            roleTitle: fallbackRoleTitle,
            roleDefinition: fallbackRoleDefinition,
            expectedAdjacentPercent: min(100, max(0, fallbackExpectedAdjacentPercent))
        )
        let storedBaseline = drift.latestBaseline
        let baseline = storedBaseline ?? fallback

        var evidence: [ResponsibilityDriftEvidenceItem] = []
        var linkedNodesByEvidenceID: [String: Set<WorkGraphNodeRef>] = [:]

        for record in accomplishments.accomplishments {
            let id = "accomplishment:\(record.id.uuidString)"
            let ref = WorkGraphNodeRef(kind: .accomplishment, nodeID: record.id)
            evidence.append(ResponsibilityDriftEvidenceItem(
                id: id,
                date: record.date,
                kind: .accomplishment,
                title: record.title,
                scope: record.responsibilityScope,
                summary: firstNonEmpty([record.businessImpact, record.outcome, record.actionTaken, record.context]),
                workLevel: record.workLevel,
                claimStrength: record.claimStrength,
                evidenceCount: record.evidence.count,
                measuredBurdenMinutes: 0,
                estimatedBurdenMinutes: 0,
                nodeRef: ref
            ))
            linkedNodesByEvidenceID[id] = expandedEntityLinks(
                direct: [],
                source: ref,
                graph: graph
            )
        }

        for record in incidents.incidents {
            let id = "incident:\(record.id.uuidString)"
            let ref = WorkGraphNodeRef(kind: .incident, nodeID: record.id)
            evidence.append(ResponsibilityDriftEvidenceItem(
                id: id,
                date: record.occurredAt,
                kind: .incident,
                title: record.title,
                scope: record.responsibilityScope ?? .unclassified,
                summary: firstNonEmpty([record.impact, record.response, record.resolution, record.observedFacts]),
                workLevel: nil,
                claimStrength: nil,
                evidenceCount: record.evidence.count,
                measuredBurdenMinutes: 0,
                estimatedBurdenMinutes: 0,
                nodeRef: ref
            ))
            linkedNodesByEvidenceID[id] = expandedEntityLinks(direct: [], source: ref, graph: graph)
        }

        for record in prevention.records {
            let id = "prevention:\(record.id.uuidString)"
            evidence.append(ResponsibilityDriftEvidenceItem(
                id: id,
                date: record.date,
                kind: .prevention,
                title: record.title,
                scope: record.responsibilityScope ?? .unclassified,
                summary: firstNonEmpty([record.observedResult, record.actionTaken, record.riskOrFailureMode]),
                workLevel: nil,
                claimStrength: nil,
                evidenceCount: 0,
                measuredBurdenMinutes: 0,
                estimatedBurdenMinutes: 0,
                nodeRef: record.sourceRecord
            ))
            linkedNodesByEvidenceID[id] = expandedEntityLinks(
                direct: record.linkedNodes,
                source: record.sourceRecord,
                graph: graph
            )
        }

        for record in burden.records {
            let id = "burden:\(record.id.uuidString)"
            let measured = record.evidenceBasis == .measured ? record.totalBurdenMinutes : 0
            let estimated = record.evidenceBasis == .estimated ? record.totalBurdenMinutes : 0
            evidence.append(ResponsibilityDriftEvidenceItem(
                id: id,
                date: record.date,
                kind: .burden,
                title: record.title,
                scope: record.responsibilityScope ?? .unclassified,
                summary: firstNonEmpty([record.impactOnPlannedWork, record.description, record.triggerOrSource]),
                workLevel: nil,
                claimStrength: nil,
                evidenceCount: 0,
                measuredBurdenMinutes: measured,
                estimatedBurdenMinutes: estimated,
                nodeRef: record.sourceRecord
            ))
            linkedNodesByEvidenceID[id] = expandedEntityLinks(
                direct: record.linkedNodes,
                source: record.sourceRecord,
                graph: graph
            )
        }

        evidence.sort { lhs, rhs in
            if lhs.date != rhs.date { return lhs.date > rhs.date }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }

        let periods = buildPeriods(
            evidence: evidence,
            drift: drift,
            fallback: fallback
        )

        let catalog = WorkGraphCatalog.nodes(
            incidents: incidents,
            accomplishments: accomplishments,
            graph: graph
        )

        let ownershipSignals = buildOwnershipSignals(
            evidence: evidence,
            linkedNodesByEvidenceID: linkedNodesByEvidenceID,
            catalog: catalog
        )

        return ResponsibilityDriftReport(
            baseline: baseline,
            usesFallbackBaseline: storedBaseline == nil,
            evidence: evidence,
            periods: periods,
            ownershipSignals: ownershipSignals
        )
    }

    private static func buildPeriods(
        evidence: [ResponsibilityDriftEvidenceItem],
        drift: ResponsibilityDriftStore,
        fallback: RoleBaselineSnapshot
    ) -> [ResponsibilityDriftPeriod] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: evidence) { item in
            calendar.date(from: calendar.dateComponents([.year, .month], from: item.date)) ?? item.date
        }

        return grouped.map { month, items in
            let baseline = drift.baseline(effectiveOn: month) ?? fallback
            return ResponsibilityDriftPeriod(
                month: month,
                coreCount: items.filter { $0.scope == .core }.count,
                otherCount: items.filter { $0.scope == .other }.count,
                unclassifiedCount: items.filter { $0.scope == .unclassified }.count,
                measuredOtherBurdenMinutes: items.filter { $0.scope == .other }.reduce(0) { $0 + $1.measuredBurdenMinutes },
                estimatedOtherBurdenMinutes: items.filter { $0.scope == .other }.reduce(0) { $0 + $1.estimatedBurdenMinutes },
                expectedAdjacentPercent: baseline.expectedAdjacentPercent
            )
        }
        .sorted { $0.month < $1.month }
    }

    private static func buildOwnershipSignals(
        evidence: [ResponsibilityDriftEvidenceItem],
        linkedNodesByEvidenceID: [String: Set<WorkGraphNodeRef>],
        catalog: [WorkGraphCatalogNode]
    ) -> [ResponsibilityOwnershipSignal] {
        var supports: [WorkGraphNodeRef: [ResponsibilityDriftEvidenceItem]] = [:]

        for item in evidence where item.isOutOfRole {
            for ref in linkedNodesByEvidenceID[item.id] ?? [] where [.system, .project].contains(ref.kind) {
                supports[ref, default: []].append(item)
            }
        }

        return supports.compactMap { ref, items in
            guard let node = catalog.first(where: { $0.ref == ref }) else { return nil }
            let sorted = items.sorted { $0.date < $1.date }
            guard let first = sorted.first, let last = sorted.last else { return nil }

            return ResponsibilityOwnershipSignal(
                node: node,
                supportingRecordCount: items.count,
                evidenceKinds: Array(Set(items.map(\.kind))).sorted { $0.rawValue < $1.rawValue },
                firstSeen: first.date,
                lastSeen: last.date,
                measuredBurdenMinutes: items.reduce(0) { $0 + $1.measuredBurdenMinutes },
                estimatedBurdenMinutes: items.reduce(0) { $0 + $1.estimatedBurdenMinutes }
            )
        }
        .sorted {
            if $0.supportingRecordCount != $1.supportingRecordCount {
                return $0.supportingRecordCount > $1.supportingRecordCount
            }
            if $0.lastSeen != $1.lastSeen { return $0.lastSeen > $1.lastSeen }
            return $0.node.title.localizedCaseInsensitiveCompare($1.node.title) == .orderedAscending
        }
    }

    private static func expandedEntityLinks(
        direct: [WorkGraphNodeRef],
        source: WorkGraphNodeRef?,
        graph: WorkGraphStore
    ) -> Set<WorkGraphNodeRef> {
        var result = Set(direct.filter { [.person, .system, .project].contains($0.kind) })

        let seedNodes = direct + (source.map { [$0] } ?? [])
        for seed in seedNodes {
            for link in graph.links(for: seed) {
                guard let other = link.otherNode(than: seed) else { continue }
                if [.person, .system, .project].contains(other.kind) {
                    result.insert(other)
                }
            }
        }

        return result
    }

    private static func firstNonEmpty(_ values: [String]) -> String {
        values.first {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } ?? ""
    }
}
