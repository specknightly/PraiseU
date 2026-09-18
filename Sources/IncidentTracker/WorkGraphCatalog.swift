import Foundation

@MainActor
enum WorkGraphCatalog {
    static func nodes(
        incidents: IncidentStore,
        accomplishments: AccomplishmentStore,
        graph: WorkGraphStore
    ) -> [WorkGraphCatalogNode] {
        var result: [WorkGraphCatalogNode] = []

        for incident in incidents.incidents {
            result.append(WorkGraphCatalogNode(
                ref: WorkGraphNodeRef(kind: .incident, nodeID: incident.id),
                title: incident.title,
                subtitle: "\(incident.category) · \(incident.severity.rawValue) · \(incident.status.rawValue)",
                date: incident.occurredAt
            ))
            for evidence in incident.evidence {
                result.append(WorkGraphCatalogNode(
                    ref: WorkGraphNodeRef(kind: .evidence, nodeID: evidence.id, parentID: incident.id),
                    title: evidence.originalName,
                    subtitle: "Incident evidence · \(incident.title)",
                    date: evidence.importedAt
                ))
            }
        }

        for accomplishment in accomplishments.accomplishments {
            result.append(WorkGraphCatalogNode(
                ref: WorkGraphNodeRef(kind: .accomplishment, nodeID: accomplishment.id),
                title: accomplishment.title,
                subtitle: "\(accomplishment.category.rawValue) · \(accomplishment.workLevel.rawValue)",
                date: accomplishment.date
            ))
            for evidence in accomplishment.evidence {
                result.append(WorkGraphCatalogNode(
                    ref: WorkGraphNodeRef(kind: .evidence, nodeID: evidence.id, parentID: accomplishment.id),
                    title: evidence.originalName,
                    subtitle: "Accomplishment evidence · \(accomplishment.title)",
                    date: evidence.importedAt
                ))
            }
        }

        for entity in graph.entities {
            result.append(WorkGraphCatalogNode(
                ref: entity.nodeRef,
                title: entity.name,
                subtitle: entity.notes.isEmpty ? entity.kind.rawValue : entity.notes,
                date: entity.modifiedAt
            ))
        }

        return result.sorted {
            if $0.kind.rawValue != $1.kind.rawValue { return $0.kind.rawValue < $1.kind.rawValue }
            if let left = $0.date, let right = $1.date, left != right { return left > right }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    static func resolve(
        _ ref: WorkGraphNodeRef,
        incidents: IncidentStore,
        accomplishments: AccomplishmentStore,
        graph: WorkGraphStore
    ) -> WorkGraphCatalogNode? {
        nodes(incidents: incidents, accomplishments: accomplishments, graph: graph).first { $0.ref == ref }
    }
}
