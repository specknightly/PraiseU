import Foundation

struct ContextualRecallResult: Identifiable, Hashable {
    let node: WorkGraphCatalogNode
    let score: Double
    let reasons: [String]

    var id: String { node.id }

    var confidenceLabel: String {
        if score >= 100 { return "Explicit" }
        if score >= 65 { return "High" }
        if score >= 35 { return "Medium" }
        return "Supporting"
    }
}

@MainActor
enum ContextualRecallEngine {
    static func recall(
        for subject: WorkGraphNodeRef,
        incidents: IncidentStore,
        accomplishments: AccomplishmentStore,
        graph: WorkGraphStore,
        limit: Int = 10
    ) -> [ContextualRecallResult] {
        let catalog = WorkGraphCatalog.nodes(incidents: incidents, accomplishments: accomplishments, graph: graph)
        let candidates = catalog.filter {
            $0.ref != subject && ($0.kind == .incident || $0.kind == .accomplishment)
        }

        let subjectTags = tags(for: subject, incidents: incidents, accomplishments: accomplishments)
        let subjectCategory = category(for: subject, incidents: incidents, accomplishments: accomplishments)
        let subjectDate = date(for: subject, incidents: incidents, accomplishments: accomplishments)
        let subjectTerms = terms(for: subject, incidents: incidents, accomplishments: accomplishments)
        let subjectLinks = graph.links(for: subject)

        let results = candidates.compactMap { candidate -> ContextualRecallResult? in
            var score = 0.0
            var reasons: [String] = []

            if let direct = subjectLinks.first(where: { $0.otherNode(than: subject) == candidate.ref }) {
                score += 120
                reasons.append("Explicit relationship: \(direct.relationship.rawValue)")
            }

            let sharedGraphContext = sharedContext(
                subject: subject,
                candidate: candidate.ref,
                subjectLinks: subjectLinks,
                graph: graph,
                catalog: catalog
            )
            score += sharedGraphContext.score
            reasons.append(contentsOf: sharedGraphContext.reasons)

            let candidateTags = tags(for: candidate.ref, incidents: incidents, accomplishments: accomplishments)
            let sharedTags = subjectTags.intersection(candidateTags).sorted()
            if !sharedTags.isEmpty {
                score += min(36, Double(sharedTags.count) * 12)
                reasons.append("Shared tag\(sharedTags.count == 1 ? "" : "s"): \(sharedTags.prefix(3).joined(separator: ", "))")
            }

            if let subjectCategory,
               let candidateCategory = category(for: candidate.ref, incidents: incidents, accomplishments: accomplishments),
               subjectCategory.caseInsensitiveCompare(candidateCategory) == .orderedSame {
                score += 15
                reasons.append("Same category: \(subjectCategory)")
            }

            if let subjectDate,
               let candidateDate = candidate.date {
                let days = abs(Calendar.current.dateComponents([.day], from: subjectDate, to: candidateDate).day ?? 99999)
                switch days {
                case 0...7:
                    score += 18
                    reasons.append("Within one week")
                case 8...30:
                    score += 12
                    reasons.append("Within one month")
                case 31...90:
                    score += 8
                    reasons.append("Within three months")
                case 91...365:
                    score += 4
                    reasons.append("Within one year")
                default:
                    break
                }
            }

            let candidateTerms = terms(for: candidate.ref, incidents: incidents, accomplishments: accomplishments)
            let sharedTerms = subjectTerms.intersection(candidateTerms)
            if sharedTerms.count >= 2 {
                score += min(15, Double(sharedTerms.count) * 2.5)
                reasons.append("Shared record language: \(sharedTerms.sorted().prefix(4).joined(separator: ", "))")
            }

            guard score >= 8 else { return nil }
            return ContextualRecallResult(node: candidate, score: score, reasons: reasons)
        }

        return results.sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            return ($0.node.date ?? .distantPast) > ($1.node.date ?? .distantPast)
        }
        .prefix(max(1, limit))
        .map { $0 }
    }

    static func contextBundle(
        subject: WorkGraphNodeRef,
        selected results: [ContextualRecallResult],
        incidents: IncidentStore,
        accomplishments: AccomplishmentStore,
        graph: WorkGraphStore,
        maxCharacters: Int = 14000
    ) -> String {
        let catalog = WorkGraphCatalog.nodes(incidents: incidents, accomplishments: accomplishments, graph: graph)
        let subjectNode = catalog.first { $0.ref == subject }
        var sections: [String] = []

        sections.append("""
        CONTEXTUAL RECALL BUNDLE
        SOURCE: \(subjectNode?.kind.rawValue ?? subject.kind.rawValue) | \(subjectNode?.title ?? subject.nodeID.uuidString)
        POLICY: Explicit graph relationships outrank inferred similarity. Retrieval reasons are signals, not proof of causation. Treat source records as evidence and recall scores as ranking metadata only.
        """)

        for result in results {
            let reasonText = result.reasons.joined(separator: "; ")
            let header = """
            ---
            RELATED RECORD
            TYPE: \(result.node.kind.rawValue)
            TITLE: \(result.node.title)
            DATE: \(result.node.date?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
            RECALL SCORE: \(Int(result.score.rounded()))
            RECALL CLASS: \(result.confidenceLabel)
            RETRIEVED BECAUSE: \(reasonText)
            """
            sections.append(header + "\n" + recordBody(for: result.node.ref, incidents: incidents, accomplishments: accomplishments))
        }

        return String(sections.joined(separator: "\n").prefix(maxCharacters))
    }

    private static func sharedContext(
        subject: WorkGraphNodeRef,
        candidate: WorkGraphNodeRef,
        subjectLinks: [WorkGraphLink],
        graph: WorkGraphStore,
        catalog: [WorkGraphCatalogNode]
    ) -> (score: Double, reasons: [String]) {
        var score = 0.0
        var reasons: [String] = []
        var seen: Set<String> = []

        for subjectLink in subjectLinks {
            guard let bridge = subjectLink.otherNode(than: subject) else { continue }
            guard [.person, .system, .project, .evidence].contains(bridge.kind) else { continue }

            let candidateTouchesBridge = graph.links(for: candidate).contains {
                $0.otherNode(than: candidate) == bridge
            }
            guard candidateTouchesBridge else { continue }

            let key = bridge.stableKey
            guard seen.insert(key).inserted else { continue }

            let bridgeNode = catalog.first { $0.ref == bridge }
            let title = bridgeNode?.title ?? bridge.kind.rawValue
            if bridge.kind == .evidence {
                score += 80
                reasons.append("Shared evidence: \(title)")
            } else {
                score += 65
                reasons.append("Shared \(bridge.kind.rawValue.lowercased()): \(title)")
            }
        }

        return (min(score, 195), reasons)
    }

    private static func tags(
        for ref: WorkGraphNodeRef,
        incidents: IncidentStore,
        accomplishments: AccomplishmentStore
    ) -> Set<String> {
        switch ref.kind {
        case .incident:
            return Set((incidents.incident(id: ref.nodeID)?.tags ?? []).map { $0.lowercased() })
        case .accomplishment:
            return Set((accomplishments.accomplishment(id: ref.nodeID)?.tags ?? []).map { $0.lowercased() })
        default:
            return []
        }
    }

    private static func category(
        for ref: WorkGraphNodeRef,
        incidents: IncidentStore,
        accomplishments: AccomplishmentStore
    ) -> String? {
        switch ref.kind {
        case .incident:
            return incidents.incident(id: ref.nodeID)?.category
        case .accomplishment:
            return accomplishments.accomplishment(id: ref.nodeID)?.category.rawValue
        default:
            return nil
        }
    }

    private static func date(
        for ref: WorkGraphNodeRef,
        incidents: IncidentStore,
        accomplishments: AccomplishmentStore
    ) -> Date? {
        switch ref.kind {
        case .incident:
            return incidents.incident(id: ref.nodeID)?.occurredAt
        case .accomplishment:
            return accomplishments.accomplishment(id: ref.nodeID)?.date
        default:
            return nil
        }
    }

    private static func terms(
        for ref: WorkGraphNodeRef,
        incidents: IncidentStore,
        accomplishments: AccomplishmentStore
    ) -> Set<String> {
        let source: String
        switch ref.kind {
        case .incident:
            guard let record = incidents.incident(id: ref.nodeID) else { return [] }
            source = [
                record.title, record.category, record.tagsText, record.observedFacts,
                record.impact, record.response, record.resolution, record.locationOrSystem,
                record.peopleInvolved, record.referenceNumbers
            ].joined(separator: " ")
        case .accomplishment:
            guard let record = accomplishments.accomplishment(id: ref.nodeID) else { return [] }
            source = [
                record.title, record.category.rawValue, record.tagsText, record.context,
                record.actionTaken, record.outcome, record.businessImpact, record.metrics,
                record.stakeholders
            ].joined(separator: " ")
        default:
            return []
        }

        let stopWords: Set<String> = [
            "about", "after", "again", "against", "because", "before", "being", "between",
            "could", "during", "from", "have", "into", "other", "should", "their", "there",
            "these", "they", "this", "through", "under", "using", "were", "what", "when",
            "where", "which", "while", "with", "would", "your"
        ]

        let parts = source.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
        return Set(parts.filter { $0.count >= 4 && !stopWords.contains($0) })
    }

    private static func recordBody(
        for ref: WorkGraphNodeRef,
        incidents: IncidentStore,
        accomplishments: AccomplishmentStore
    ) -> String {
        switch ref.kind {
        case .incident:
            guard let record = incidents.incident(id: ref.nodeID) else { return "Record unavailable." }
            return """
            CATEGORY: \(record.category)
            SEVERITY: \(record.severity.rawValue)
            STATUS: \(record.status.rawValue)
            FACTS: \(record.observedFacts.prefix(900))
            IMPACT: \(record.impact.prefix(600))
            RESPONSE: \(record.response.prefix(600))
            RESOLUTION: \(record.resolution.prefix(500))
            """
        case .accomplishment:
            guard let record = accomplishments.accomplishment(id: ref.nodeID) else { return "Record unavailable." }
            return """
            CATEGORY: \(record.category.rawValue)
            WORK LEVEL: \(record.workLevel.rawValue)
            RESPONSIBILITY: \(record.responsibilityScope.rawValue)
            CONTEXT: \(record.context.prefix(700))
            ACTION: \(record.actionTaken.prefix(900))
            OUTCOME: \(record.outcome.prefix(600))
            IMPACT: \(record.businessImpact.prefix(600))
            """
        default:
            return "Record unavailable."
        }
    }
}
