import Foundation

@MainActor
enum WorkIntelligenceRetrievalEngine {
    static func retrieve(
        question: String,
        subject: WorkGraphNodeRef?,
        incidents: IncidentStore,
        accomplishments: AccomplishmentStore,
        prevention: PreventionLedgerStore,
        burden: OperationalBurdenStore,
        graph: WorkGraphStore,
        drift: ResponsibilityDriftStore,
        fallbackRoleTitle: String,
        fallbackRoleDefinition: String,
        fallbackExpectedAdjacentPercent: Double,
        maxSources: Int = 12
    ) -> [WorkIntelligenceSource] {
        let query = normalizedTerms(question)
        let intents = intentSignals(question)
        let catalog = WorkGraphCatalog.nodes(
            incidents: incidents,
            accomplishments: accomplishments,
            graph: graph
        )

        var sources: [WorkIntelligenceSource] = []

        for record in incidents.incidents {
            let ref = WorkGraphNodeRef(kind: .incident, nodeID: record.id)
            let text = [
                record.title, record.category, record.tagsText, record.observedFacts,
                record.contextInterpretation, record.impact, record.response, record.resolution,
                record.followUp, record.locationOrSystem, record.peopleInvolved, record.witnesses,
                record.referenceNumbers, record.notes
            ].joined(separator: " ")

            let scored = score(
                terms: query,
                candidateText: text,
                subject: subject,
                candidateRef: ref,
                graph: graph,
                catalog: catalog,
                kindBoost: intents.incident ? 28 : 0,
                scopeBoost: record.responsibilityScope == .other && intents.drift ? 24 : 0,
                evidenceCount: record.evidence.count
            )

            sources.append(WorkIntelligenceSource(
                id: "incident:\(record.id.uuidString)",
                kind: .incident,
                title: record.title,
                subtitle: "\(record.category) · \(record.severity.rawValue) · \(record.status.rawValue)",
                date: record.occurredAt,
                score: scored.score,
                reasons: scored.reasons,
                contextText: incidentContext(record, graph: graph, catalog: catalog),
                nodeRef: ref
            ))

            for evidence in record.evidence {
                let evidenceText = "\(evidence.originalName) \(evidence.note) \(record.title) \(record.category)"
                let evidenceScore = lexicalScore(query, normalizedTerms(evidenceText))
                    + (subject == ref ? 95 : 0)
                    + (intents.evidence ? 24 : 0)
                if evidenceScore > 0 {
                    sources.append(WorkIntelligenceSource(
                        id: "incident-evidence:\(evidence.id.uuidString)",
                        kind: .evidence,
                        title: evidence.originalName,
                        subtitle: "Incident evidence · \(record.title)",
                        date: evidence.importedAt,
                        score: evidenceScore,
                        reasons: evidenceReasons(query: query, text: evidenceText, parentSelected: subject == ref),
                        contextText: """
                        EVIDENCE TYPE: Incident attachment
                        PARENT RECORD: \(record.title)
                        FILE NAME: \(evidence.originalName)
                        IMPORTED: \(evidence.importedAt.formatted(date: .abbreviated, time: .shortened))
                        SHA-256: \(evidence.sha256)
                        NOTE: \(evidence.note)
                        BYTE COUNT: \(evidence.byteCount)
                        POLICY: Attachment metadata is evidence provenance. File contents are not included in this assistant context unless captured elsewhere in the record.
                        """,
                        nodeRef: WorkGraphNodeRef(kind: .evidence, nodeID: evidence.id, parentID: record.id)
                    ))
                }
            }
        }

        for record in accomplishments.accomplishments {
            let ref = WorkGraphNodeRef(kind: .accomplishment, nodeID: record.id)
            let text = [
                record.title, record.category.rawValue, record.tagsText, record.context,
                record.actionTaken, record.outcome, record.businessImpact, record.evidenceNotes,
                record.metrics, record.stakeholders, record.humanValueAnalysis, record.scopeInference,
                record.professionalIntelligence, record.evidenceAnalysis
            ].joined(separator: " ")

            let scored = score(
                terms: query,
                candidateText: text,
                subject: subject,
                candidateRef: ref,
                graph: graph,
                catalog: catalog,
                kindBoost: intents.accomplishment ? 30 : 0,
                scopeBoost: record.responsibilityScope == .other && intents.drift ? 28 : 0,
                evidenceCount: record.evidence.count
            )

            let levelBoost: Double = intents.promotion && [.advanced, .specialist, .projectOwner, .strategic].contains(record.workLevel) ? 24 : 0

            sources.append(WorkIntelligenceSource(
                id: "accomplishment:\(record.id.uuidString)",
                kind: .accomplishment,
                title: record.title,
                subtitle: "\(record.category.rawValue) · \(record.workLevel.rawValue) · \(record.responsibilityScope.rawValue)",
                date: record.date,
                score: scored.score + levelBoost + (intents.promotion ? Double(record.claimStrength) * 0.12 : 0),
                reasons: scored.reasons + (levelBoost > 0 ? ["Higher-level accomplishment relevant to promotion"] : []),
                contextText: accomplishmentContext(record, graph: graph, catalog: catalog),
                nodeRef: ref
            ))

            for evidence in record.evidence {
                let evidenceText = "\(evidence.originalName) \(evidence.note) \(record.title) \(record.category.rawValue)"
                let evidenceScore = lexicalScore(query, normalizedTerms(evidenceText))
                    + (subject == ref ? 95 : 0)
                    + (intents.evidence ? 24 : 0)
                if evidenceScore > 0 {
                    sources.append(WorkIntelligenceSource(
                        id: "accomplishment-evidence:\(evidence.id.uuidString)",
                        kind: .evidence,
                        title: evidence.originalName,
                        subtitle: "Accomplishment evidence · \(record.title)",
                        date: evidence.importedAt,
                        score: evidenceScore,
                        reasons: evidenceReasons(query: query, text: evidenceText, parentSelected: subject == ref),
                        contextText: """
                        EVIDENCE TYPE: Accomplishment attachment
                        PARENT RECORD: \(record.title)
                        FILE NAME: \(evidence.originalName)
                        IMPORTED: \(evidence.importedAt.formatted(date: .abbreviated, time: .shortened))
                        SHA-256: \(evidence.sha256)
                        NOTE: \(evidence.note)
                        BYTE COUNT: \(evidence.byteCount)
                        POLICY: Attachment metadata is evidence provenance. File contents are not included in this assistant context unless captured elsewhere in the record.
                        """,
                        nodeRef: WorkGraphNodeRef(kind: .evidence, nodeID: evidence.id, parentID: record.id)
                    ))
                }
            }
        }

        for record in prevention.records {
            let text = [
                record.title, record.type.rawValue, record.evidenceBasis.rawValue,
                record.actionTaken, record.riskOrFailureMode, record.expectedConsequence,
                record.observedResult, record.measurementBasis, record.notes
            ].joined(separator: " ")

            var scoreValue = lexicalScore(query, normalizedTerms(text))
            var reasons = matchedReasons(query, text)
            if intents.prevention {
                scoreValue += 34
                reasons.append("Question asks about prevention or avoided risk")
            }
            if record.responsibilityScope == .other && intents.drift {
                scoreValue += 22
                reasons.append("Explicitly classified as Other / Scope Drift")
            }
            if let subject, record.sourceRecord == subject || record.linkedNodes.contains(subject) {
                scoreValue += 105
                reasons.append("Directly linked to the current record")
            }
            scoreValue += linkedEntityQueryBoost(
                query: query,
                refs: record.linkedNodes + (record.sourceRecord.map { [$0] } ?? []),
                catalog: catalog,
                reasons: &reasons
            )

            sources.append(WorkIntelligenceSource(
                id: "prevention:\(record.id.uuidString)",
                kind: .prevention,
                title: record.title,
                subtitle: "\(record.type.rawValue) · \(record.evidenceBasis.rawValue) · \(record.responsibilityScope?.rawValue ?? "Unclassified")",
                date: record.date,
                score: scoreValue,
                reasons: reasons,
                contextText: """
                PREVENTION RECORD: \(record.title)
                DATE: \(record.date.formatted(date: .abbreviated, time: .omitted))
                TYPE: \(record.type.rawValue)
                EVIDENCE BASIS: \(record.evidenceBasis.rawValue)
                ROLE SCOPE: \(record.responsibilityScope?.rawValue ?? "Unclassified")
                ACTION: \(record.actionTaken.prefix(900))
                RISK / FAILURE MODE: \(record.riskOrFailureMode.prefix(700))
                EXPECTED CONSEQUENCE: \(record.expectedConsequence.prefix(600))
                OBSERVED RESULT: \(record.observedResult.prefix(700))
                MEASUREMENT BASIS: \(record.measurementBasis.prefix(650))
                QUANTIFICATION: \(record.quantificationSummary)
                POLICY: Expected consequence is a risk statement. It is not proof that the event definitely would have occurred.
                """,
                nodeRef: record.sourceRecord
            ))
        }

        for record in burden.records {
            let text = [
                record.title, record.kind.rawValue, record.description, record.triggerOrSource,
                record.impactOnPlannedWork, record.measurementBasis, record.notes
            ].joined(separator: " ")

            var scoreValue = lexicalScore(query, normalizedTerms(text))
            var reasons = matchedReasons(query, text)
            if intents.burden {
                scoreValue += 34
                reasons.append("Question asks about workload or operational burden")
            }
            if record.responsibilityScope == .other && intents.drift {
                scoreValue += 22
                reasons.append("Explicitly classified as Other / Scope Drift")
            }
            if let subject, record.sourceRecord == subject || record.linkedNodes.contains(subject) {
                scoreValue += 105
                reasons.append("Directly linked to the current record")
            }
            scoreValue += linkedEntityQueryBoost(
                query: query,
                refs: record.linkedNodes + (record.sourceRecord.map { [$0] } ?? []),
                catalog: catalog,
                reasons: &reasons
            )

            sources.append(WorkIntelligenceSource(
                id: "burden:\(record.id.uuidString)",
                kind: .burden,
                title: record.title,
                subtitle: "\(record.kind.rawValue) · \(record.evidenceBasis.rawValue) · \(record.responsibilityScope?.rawValue ?? "Unclassified")",
                date: record.date,
                score: scoreValue,
                reasons: reasons,
                contextText: """
                OPERATIONAL BURDEN: \(record.title)
                DATE: \(record.date.formatted(date: .abbreviated, time: .omitted))
                TYPE: \(record.kind.rawValue)
                TIME BASIS: \(record.evidenceBasis.rawValue)
                ROLE SCOPE: \(record.responsibilityScope?.rawValue ?? "Unclassified")
                DESCRIPTION: \(record.description.prefix(850))
                TRIGGER / SOURCE: \(record.triggerOrSource.prefix(600))
                IMPACT ON PLANNED WORK: \(record.impactOnPlannedWork.prefix(650))
                ACTIVE MINUTES: \(record.durationMinutes.map(String.init) ?? "UNCLAIMED")
                RECOVERY MINUTES: \(record.recoveryMinutes.map(String.init) ?? "UNCLAIMED")
                AFTER-HOURS MINUTES: \(record.afterHoursMinutes.map(String.init) ?? "UNCLAIMED")
                INTERRUPTIONS: \(record.interruptionCount.map(String.init) ?? "UNCLAIMED")
                CONTEXT SWITCHES: \(record.contextSwitchCount.map(String.init) ?? "UNCLAIMED")
                COGNITIVE LOAD SELF-REPORT: \(record.cognitiveLoad)/5
                COORDINATION LOAD SELF-REPORT: \(record.coordinationLoad)/5
                MEASUREMENT BASIS: \(record.measurementBasis.prefix(650))
                POLICY: Self-reported load is not a medical, competence, or productivity measure.
                """,
                nodeRef: record.sourceRecord
            ))
        }

        for entity in graph.entities {
            let text = "\(entity.name) \(entity.kind.rawValue) \(entity.notes)"
            var scoreValue = lexicalScore(query, normalizedTerms(text))
            var reasons = matchedReasons(query, text)
            if intents.graphEntity {
                scoreValue += 18
                reasons.append("Question asks about people, systems, or projects")
            }
            if subject != nil && graph.links(for: entity.nodeRef).contains(where: { $0.touches(subject!) }) {
                scoreValue += 75
                reasons.append("Connected to the current record")
            }

            let relations = graph.links(for: entity.nodeRef).prefix(16).map { link -> String in
                guard let other = link.otherNode(than: entity.nodeRef) else { return "" }
                let otherNode = catalog.first { $0.ref == other }
                return "\(link.relationship.rawValue): \(otherNode?.title ?? other.kind.rawValue)"
            }.filter { !$0.isEmpty }

            let kind: WorkIntelligenceSourceKind = {
                switch entity.kind {
                case .person: return .person
                case .system: return .system
                case .project: return .project
                default: return .project
                }
            }()

            sources.append(WorkIntelligenceSource(
                id: "graph-entity:\(entity.id.uuidString)",
                kind: kind,
                title: entity.name,
                subtitle: "\(entity.kind.rawValue) · \(graph.relationshipCount(for: entity.nodeRef)) relationships",
                date: entity.modifiedAt,
                score: scoreValue,
                reasons: reasons,
                contextText: """
                GRAPH ENTITY: \(entity.name)
                TYPE: \(entity.kind.rawValue)
                NOTES: \(entity.notes.prefix(800))
                EXPLICIT RELATIONSHIPS:
                \(relations.joined(separator: "\n").prefix(2500))
                POLICY: A relationship is explicit context, but does not by itself prove formal ownership, intent, or causation.
                """,
                nodeRef: entity.nodeRef
            ))
        }

        let fallback = RoleBaselineSnapshot(
            effectiveDate: Date(),
            roleTitle: fallbackRoleTitle,
            roleDefinition: fallbackRoleDefinition,
            expectedAdjacentPercent: fallbackExpectedAdjacentPercent
        )
        let baseline = drift.latestBaseline ?? fallback
        let baselineText = "\(baseline.roleTitle) \(baseline.roleDefinition) scope role responsibility adjacent work"
        var baselineScore = lexicalScore(query, normalizedTerms(baselineText))
        var baselineReasons = matchedReasons(query, baselineText)
        if intents.drift || intents.promotion {
            baselineScore += 38
            baselineReasons.append("Role baseline is relevant to scope or advancement")
        }
        sources.append(WorkIntelligenceSource(
            id: "role-baseline:\(baseline.id.uuidString)",
            kind: .roleBaseline,
            title: baseline.displayTitle,
            subtitle: drift.latestBaseline == nil ? "Current Settings baseline · unsnapshotted" : "Saved role baseline",
            date: drift.latestBaseline == nil ? nil : baseline.effectiveDate,
            score: baselineScore,
            reasons: baselineReasons,
            contextText: """
            ROLE BASELINE: \(baseline.displayTitle)
            SOURCE: \(drift.latestBaseline == nil ? "Current Settings (not a dated historical snapshot)" : "Saved dated baseline")
            EFFECTIVE DATE: \(drift.latestBaseline == nil ? "Not historically established" : baseline.effectiveDate.formatted(date: .abbreviated, time: .omitted))
            EXPECTED ADJACENT / OUT-OF-ROLE ALLOWANCE: \(Int(baseline.expectedAdjacentPercent.rounded()))%
            ROLE DEFINITION: \(baseline.roleDefinition.prefix(2500))
            NOTES: \(baseline.notes.prefix(700))
            POLICY: This baseline is comparison context. Scope classifications are user-entered and should be corroborated for formal employment claims.
            """,
            nodeRef: nil
        ))

        var ranked = sources
            .filter { $0.score > 0 || $0.nodeRef == subject }
            .sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                return ($0.date ?? .distantPast) > ($1.date ?? .distantPast)
            }

        if ranked.isEmpty {
            ranked = sources.sorted {
                ($0.date ?? .distantPast) > ($1.date ?? .distantPast)
            }
        }

        var deduped: [WorkIntelligenceSource] = []
        var seen: Set<String> = []

        for source in ranked where seen.insert(source.id).inserted {
            deduped.append(source)
            if deduped.count >= max(1, maxSources) { break }
        }

        return deduped
    }

    static func packet(
        question: String,
        sources: [WorkIntelligenceSource],
        maxCharacters: Int = 22000
    ) -> String {
        var output = """
        WORK INTELLIGENCE SOURCE PACKET
        QUESTION: \(question)
        SOURCE COUNT: \(sources.count)
        POLICY: Only the sources below may be treated as record evidence. Retrieval scores rank relevance; they are not proof. Explicit graph links are context, not automatic causation or formal ownership.

        """

        for (index, source) in sources.enumerated() {
            let label = "S\(index + 1)"
            let date = source.date?.formatted(date: .abbreviated, time: .omitted) ?? "Undated"
            let reasons = source.reasons.isEmpty ? "General relevance / fallback" : source.reasons.joined(separator: "; ")
            output += """
            [\(label)]
            TYPE: \(source.kind.rawValue)
            TITLE: \(source.title)
            DATE: \(date)
            RETRIEVAL SCORE: \(Int(source.score.rounded()))
            RETRIEVAL CLASS: \(source.confidenceLabel)
            RETRIEVED BECAUSE: \(reasons)
            \(source.contextText)

            """
            if output.count >= maxCharacters { break }
        }

        return String(output.prefix(maxCharacters))
    }

    private static func score(
        terms: Set<String>,
        candidateText: String,
        subject: WorkGraphNodeRef?,
        candidateRef: WorkGraphNodeRef,
        graph: WorkGraphStore,
        catalog: [WorkGraphCatalogNode],
        kindBoost: Double,
        scopeBoost: Double,
        evidenceCount: Int
    ) -> (score: Double, reasons: [String]) {
        var value = lexicalScore(terms, normalizedTerms(candidateText))
        var reasons = matchedReasons(terms, candidateText)

        if subject == candidateRef {
            value += 180
            reasons.append("Current record")
        } else if let subject {
            let directLinks = graph.links(for: subject)
            if let link = directLinks.first(where: { $0.otherNode(than: subject) == candidateRef }) {
                value += 115
                reasons.append("Explicit graph relationship: \(link.relationship.rawValue)")
            } else {
                let subjectEntities = relatedEntities(to: subject, graph: graph)
                let candidateEntities = relatedEntities(to: candidateRef, graph: graph)
                let shared = subjectEntities.intersection(candidateEntities)
                if !shared.isEmpty {
                    value += min(90, Double(shared.count) * 45)
                    let names = shared.compactMap { ref in catalog.first { $0.ref == ref }?.title }
                    reasons.append("Shared graph context: \(names.prefix(3).joined(separator: ", "))")
                }
            }
        }

        value += kindBoost + scopeBoost
        if kindBoost > 0 { reasons.append("Matches the question's record type") }
        if scopeBoost > 0 { reasons.append("Explicit scope-drift classification") }
        if evidenceCount > 0 {
            value += min(18, Double(evidenceCount) * 4)
            reasons.append("\(evidenceCount) evidence attachment\(evidenceCount == 1 ? "" : "s")")
        }

        return (value, reasons)
    }

    private static func incidentContext(
        _ record: IncidentRecord,
        graph: WorkGraphStore,
        catalog: [WorkGraphCatalogNode]
    ) -> String {
        let links = relationshipText(
            for: WorkGraphNodeRef(kind: .incident, nodeID: record.id),
            graph: graph,
            catalog: catalog
        )
        let evidence = record.evidence.prefix(12).map {
            "\($0.originalName) | SHA-256 \($0.sha256) | note=\($0.note)"
        }.joined(separator: "\n")

        return """
        INCIDENT: \(record.title)
        DATE: \(record.occurredAt.formatted(date: .abbreviated, time: .omitted))
        CATEGORY: \(record.category)
        SEVERITY: \(record.severity.rawValue)
        STATUS: \(record.status.rawValue)
        ROLE SCOPE: \(record.responsibilityScope?.rawValue ?? "Unclassified")
        FACTS: \(record.observedFacts.prefix(1600))
        CONTEXT / INTERPRETATION: \(record.contextInterpretation.prefix(700))
        IMPACT: \(record.impact.prefix(900))
        RESPONSE: \(record.response.prefix(900))
        RESOLUTION: \(record.resolution.prefix(800))
        FOLLOW-UP: \(record.followUp.prefix(600))
        LOCATION / SYSTEM: \(record.locationOrSystem.prefix(500))
        PEOPLE INVOLVED: \(record.peopleInvolved.prefix(500))
        REFERENCES: \(record.referenceNumbers.prefix(500))
        EVIDENCE METADATA:
        \(evidence.prefix(2200))
        EXPLICIT GRAPH RELATIONSHIPS:
        \(links.prefix(2200))
        """
    }

    private static func accomplishmentContext(
        _ record: AccomplishmentRecord,
        graph: WorkGraphStore,
        catalog: [WorkGraphCatalogNode]
    ) -> String {
        let links = relationshipText(
            for: WorkGraphNodeRef(kind: .accomplishment, nodeID: record.id),
            graph: graph,
            catalog: catalog
        )
        let evidence = record.evidence.prefix(12).map {
            "\($0.originalName) | SHA-256 \($0.sha256) | note=\($0.note)"
        }.joined(separator: "\n")

        return """
        ACCOMPLISHMENT: \(record.title)
        DATE: \(record.date.formatted(date: .abbreviated, time: .omitted))
        CATEGORY: \(record.category.rawValue)
        ROLE SCOPE: \(record.responsibilityScope.rawValue)
        WORK LEVEL: \(record.workLevel.rawValue)
        CLAIM STRENGTH: \(record.claimStrength)/100
        CONTEXT: \(record.context.prefix(1000))
        ACTION: \(record.actionTaken.prefix(1400))
        OUTCOME: \(record.outcome.prefix(900))
        BUSINESS / OPERATIONAL IMPACT: \(record.businessImpact.prefix(1000))
        METRICS: \(record.metrics.prefix(650))
        STAKEHOLDERS: \(record.stakeholders.prefix(500))
        EVIDENCE NOTES: \(record.evidenceNotes.prefix(700))
        EVIDENCE METADATA:
        \(evidence.prefix(2200))
        EXPLICIT GRAPH RELATIONSHIPS:
        \(links.prefix(2200))
        """
    }

    private static func relationshipText(
        for ref: WorkGraphNodeRef,
        graph: WorkGraphStore,
        catalog: [WorkGraphCatalogNode]
    ) -> String {
        graph.links(for: ref).prefix(16).compactMap { link in
            guard let other = link.otherNode(than: ref) else { return nil }
            let otherNode = catalog.first { $0.ref == other }
            let direction = link.source == ref ? "→" : "←"
            let note = link.note.isEmpty ? "" : " | note=\(link.note)"
            return "\(direction) \(link.relationship.rawValue) | \(other.kind.rawValue): \(otherNode?.title ?? other.nodeID.uuidString)\(note)"
        }.joined(separator: "\n")
    }

    private static func relatedEntities(
        to ref: WorkGraphNodeRef,
        graph: WorkGraphStore
    ) -> Set<WorkGraphNodeRef> {
        Set(graph.links(for: ref).compactMap { link in
            guard let other = link.otherNode(than: ref) else { return nil }
            return [.person, .system, .project].contains(other.kind) ? other : nil
        })
    }

    private static func linkedEntityQueryBoost(
        query: Set<String>,
        refs: [WorkGraphNodeRef],
        catalog: [WorkGraphCatalogNode],
        reasons: inout [String]
    ) -> Double {
        var boost = 0.0
        var seen: Set<String> = []

        for ref in refs where [.person, .system, .project].contains(ref.kind) {
            guard let node = catalog.first(where: { $0.ref == ref }) else { continue }
            let overlap = query.intersection(normalizedTerms(node.title))
            guard !overlap.isEmpty, seen.insert(ref.stableKey).inserted else { continue }
            boost += 42
            reasons.append("Linked \(ref.kind.rawValue.lowercased()) matches query: \(node.title)")
        }

        return min(boost, 126)
    }

    private static func evidenceReasons(
        query: Set<String>,
        text: String,
        parentSelected: Bool
    ) -> [String] {
        var reasons = matchedReasons(query, text)
        if parentSelected { reasons.append("Evidence belongs to the current record") }
        return reasons
    }

    private static func matchedReasons(_ query: Set<String>, _ text: String) -> [String] {
        let overlap = query.intersection(normalizedTerms(text)).sorted()
        guard !overlap.isEmpty else { return [] }
        return ["Question terms: \(overlap.prefix(5).joined(separator: ", "))"]
    }

    private static func lexicalScore(_ query: Set<String>, _ candidate: Set<String>) -> Double {
        guard !query.isEmpty else { return 1 }
        let overlap = query.intersection(candidate)
        guard !overlap.isEmpty else { return 0 }
        let coverage = Double(overlap.count) / Double(max(1, query.count))
        return Double(overlap.count) * 16 + coverage * 28
    }

    private static func normalizedTerms(_ text: String) -> Set<String> {
        let stopWords: Set<String> = [
            "about", "after", "again", "against", "also", "because", "before", "being",
            "between", "could", "does", "from", "have", "into", "just", "more", "most",
            "other", "should", "show", "that", "their", "there", "these", "they", "this",
            "through", "under", "using", "were", "what", "when", "where", "which", "while",
            "with", "would", "your", "mine", "please", "tell"
        ]

        let parts = text.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
        return Set(parts.filter { $0.count >= 3 && !stopWords.contains($0) })
    }

    private static func intentSignals(_ question: String) -> (
        incident: Bool,
        accomplishment: Bool,
        prevention: Bool,
        burden: Bool,
        drift: Bool,
        promotion: Bool,
        graphEntity: Bool,
        evidence: Bool
    ) {
        let q = question.lowercased()
        func has(_ words: [String]) -> Bool { words.contains { q.contains($0) } }

        return (
            incident: has(["incident", "failure", "problem", "dispute", "outage", "issue", "blame"]),
            accomplishment: has(["accomplishment", "win", "impact", "achievement", "success", "delivered"]),
            prevention: has(["prevent", "mitigat", "avoided", "risk", "hardening", "early detection"]),
            burden: has(["burden", "workload", "after-hours", "after hours", "interrupt", "context switch", "time spent", "coordination"]),
            drift: has(["scope", "drift", "role", "responsibil", "job description", "out-of-role", "out of role"]),
            promotion: has(["promotion", "raise", "review", "level", "title", "advancement", "compensation"]),
            graphEntity: has(["system", "project", "person", "people", "who", "stakeholder", "dependency"]),
            evidence: has(["evidence", "proof", "attachment", "document", "hash", "sha"])
        )
    }
}
