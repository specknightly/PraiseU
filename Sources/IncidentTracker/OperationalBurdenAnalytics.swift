import Foundation

struct OperationalBurdenHotspot: Identifiable, Hashable {
    let node: WorkGraphCatalogNode
    let measuredMinutes: Int
    let estimatedMinutes: Int
    let recordCount: Int
    let averageCognitiveLoad: Double
    let averageCoordinationLoad: Double

    var id: String { node.id }
    var totalMinutes: Int { measuredMinutes + estimatedMinutes }
}

@MainActor
enum OperationalBurdenAnalytics {
    static func hotspots(
        records: [OperationalBurdenRecord],
        incidents: IncidentStore,
        accomplishments: AccomplishmentStore,
        graph: WorkGraphStore
    ) -> [OperationalBurdenHotspot] {
        let catalog = WorkGraphCatalog.nodes(
            incidents: incidents,
            accomplishments: accomplishments,
            graph: graph
        )

        var grouped: [WorkGraphNodeRef: [OperationalBurdenRecord]] = [:]

        for record in records {
            var refs = Set(record.linkedNodes)
            if let source = record.sourceRecord { refs.insert(source) }

            for ref in refs where [.person, .system, .project].contains(ref.kind) {
                grouped[ref, default: []].append(record)
            }
        }

        return grouped.compactMap { ref, linkedRecords in
            guard let node = catalog.first(where: { $0.ref == ref }) else { return nil }

            let measured = linkedRecords
                .filter { $0.evidenceBasis == .measured }
                .reduce(0) { $0 + $1.totalBurdenMinutes }

            let estimated = linkedRecords
                .filter { $0.evidenceBasis == .estimated }
                .reduce(0) { $0 + $1.totalBurdenMinutes }

            let cognitive = linkedRecords.isEmpty ? 0 :
                Double(linkedRecords.reduce(0) { $0 + $1.cognitiveLoad }) / Double(linkedRecords.count)

            let coordination = linkedRecords.isEmpty ? 0 :
                Double(linkedRecords.reduce(0) { $0 + $1.coordinationLoad }) / Double(linkedRecords.count)

            return OperationalBurdenHotspot(
                node: node,
                measuredMinutes: measured,
                estimatedMinutes: estimated,
                recordCount: linkedRecords.count,
                averageCognitiveLoad: cognitive,
                averageCoordinationLoad: coordination
            )
        }
        .sorted {
            if $0.totalMinutes != $1.totalMinutes { return $0.totalMinutes > $1.totalMinutes }
            return $0.node.title.localizedCaseInsensitiveCompare($1.node.title) == .orderedAscending
        }
    }
}
