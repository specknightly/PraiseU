import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum PreventionLedgerAIService {
    static func summarize(_ records: [PreventionInterventionRecord]) async throws -> String {
        guard !records.isEmpty else { throw AccomplishmentAIError.insufficientDetail }

        let body = records.prefix(120).map { record in
            """
            DATE=\(record.date.formatted(date: .abbreviated, time: .omitted))
            TITLE=\(record.title)
            TYPE=\(record.type.rawValue)
            EVIDENCE_BASIS=\(record.evidenceBasis.rawValue)
            ACTION=\(record.actionTaken.prefix(500))
            RISK=\(record.riskOrFailureMode.prefix(400))
            EXPECTED_CONSEQUENCE=\(record.expectedConsequence.prefix(350))
            OBSERVED_RESULT=\(record.observedResult.prefix(400))
            RECURRENCES_AVOIDED=\(record.recurrenceCountAvoided.map(String.init) ?? "UNCLAIMED")
            HOURS_AVOIDED=\(record.hoursAvoided.map { String(format: "%.1f", $0) } ?? "UNCLAIMED")
            PEOPLE_OR_SYSTEMS_PROTECTED=\(record.peopleOrSystemsProtected.map(String.init) ?? "UNCLAIMED")
            BASIS=\(record.measurementBasis.prefix(500))
            """
        }.joined(separator: "\n---\n")

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard model.isAvailable else { throw AccomplishmentAIError.unavailable }
            let session = LanguageModelSession(
                model: model,
                instructions: """
                You are a conservative operational-value analyst. Summarize prevention and intervention work without inventing avoided incidents, money, savings, or causal certainty. Preserve the distinction between MEASURED, ESTIMATED, and INFERRED claims. Never add numeric values that were not supplied. Do not convert hours into dollars. Treat expected consequences as risk statements, not events that definitely would have occurred.
                """
            )
            let prompt = """
            Analyze this prevention ledger:

            \(body.prefix(18000))

            Use exactly these headings:
            Prevention portfolio
            Measured avoided burden
            Estimated avoided burden
            Inferred preventive value
            Recurring failure modes addressed
            Systems and operations protected
            Human judgment demonstrated
            Strongest defensible claims
            Claims that need stronger evidence
            Next measurements to capture

            Be skeptical and concise. If a category has no support, say so.
            """
            let text = try await session.respond(to: prompt).content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw AccomplishmentAIError.emptyResponse }
            return text
        }
        #endif

        throw AccomplishmentAIError.unsupportedOS
    }
}
