import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum OperationalBurdenAIService {
    static func analyze(
        records: [OperationalBurdenRecord],
        hotspots: [OperationalBurdenHotspot]
    ) async throws -> String {
        guard !records.isEmpty else { throw AccomplishmentAIError.insufficientDetail }

        let recordText = records.prefix(140).map { record in
            """
            DATE=\(record.date.formatted(date: .abbreviated, time: .omitted))
            TITLE=\(record.title)
            TYPE=\(record.kind.rawValue)
            BASIS=\(record.evidenceBasis.rawValue)
            ACTIVE_MINUTES=\(record.durationMinutes.map(String.init) ?? "UNCLAIMED")
            RECOVERY_MINUTES=\(record.recoveryMinutes.map(String.init) ?? "UNCLAIMED")
            AFTER_HOURS_MINUTES=\(record.afterHoursMinutes.map(String.init) ?? "UNCLAIMED")
            INTERRUPTIONS=\(record.interruptionCount.map(String.init) ?? "UNCLAIMED")
            CONTEXT_SWITCHES=\(record.contextSwitchCount.map(String.init) ?? "UNCLAIMED")
            COGNITIVE_LOAD_SELF_REPORT=\(record.cognitiveLoad)/5
            COORDINATION_LOAD_SELF_REPORT=\(record.coordinationLoad)/5
            WORK=\(record.description.prefix(450))
            TRIGGER=\(record.triggerOrSource.prefix(350))
            PLANNED_WORK_IMPACT=\(record.impactOnPlannedWork.prefix(400))
            MEASUREMENT_BASIS=\(record.measurementBasis.prefix(400))
            """
        }.joined(separator: "\n---\n")

        let hotspotText = hotspots.prefix(30).map { hotspot in
            """
            NODE=\(hotspot.node.kind.rawValue): \(hotspot.node.title)
            MEASURED_MINUTES=\(hotspot.measuredMinutes)
            ESTIMATED_MINUTES=\(hotspot.estimatedMinutes)
            RECORDS=\(hotspot.recordCount)
            AVG_COGNITIVE_SELF_REPORT=\(String(format: "%.1f", hotspot.averageCognitiveLoad))/5
            AVG_COORDINATION_SELF_REPORT=\(String(format: "%.1f", hotspot.averageCoordinationLoad))/5
            """
        }.joined(separator: "\n---\n")

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard model.isAvailable else { throw AccomplishmentAIError.unavailable }

            let session = LanguageModelSession(
                model: model,
                instructions: """
                You are a conservative operational-work analyst. Analyze where recorded work time and attention are going without judging employee competence, effort, health, personality, or worth. Never diagnose burnout or mental state. Keep MEASURED and ESTIMATED time separate. Cognitive and coordination load are subjective self-reports, not medical or productivity measurements. Do not infer manager or coworker motives. Do not convert time into money. Do not assume high burden means high value or poor performance. Linked hotspot totals can overlap because one burden record may link to multiple people, systems, or projects.
                """
            )

            let prompt = """
            OPERATIONAL BURDEN RECORDS:
            \(recordText.prefix(19000))

            GRAPH-LINKED HOTSPOTS:
            \(hotspotText.prefix(7000))

            Use exactly these headings:
            Where measured time is going
            Where estimated time is going
            Interruption and context-switch burden
            Recovery and after-hours burden
            High-coordination work
            High-cognitive-load self-reports
            Systems and projects repeatedly consuming attention
            People-linked coordination patterns
            Planned work being displaced
            What the data does not prove
            Measurements worth improving next

            Preserve uncertainty and distinguish direct observations from interpretation.
            """

            let text = try await session.respond(to: prompt).content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw AccomplishmentAIError.emptyResponse }
            return text
        }
        #endif

        throw AccomplishmentAIError.unsupportedOS
    }
}
