import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum UnifiedWorkAIService {
    static func analyze(incidents:[IncidentRecord], accomplishments:[AccomplishmentRecord], year:Int) async throws -> String {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model=SystemLanguageModel.default
            guard model.isAvailable else { throw AccomplishmentAIError.unavailable }
            let inc=incidents.filter{Calendar.current.component(.year,from:$0.occurredAt)==year}.prefix(120).map { r in
                "INCIDENT | DATE=\(r.occurredAt.formatted(date:.abbreviated,time:.omitted)) | SEVERITY=\(r.severity.rawValue) | STATUS=\(r.status.rawValue) | CATEGORY=\(r.category) | TITLE=\(r.title.prefix(160))\nFACTS=\(r.observedFacts.prefix(220))\nIMPACT=\(r.impact.prefix(180))\nRESPONSE=\(r.response.prefix(180))\nRESOLUTION=\(r.resolution.prefix(180))"
            }.joined(separator:"\n---\n")
            let acc=accomplishments.filter{Calendar.current.component(.year,from:$0.date)==year}.prefix(120).map { r in
                "ACCOMPLISHMENT | DATE=\(r.date.formatted(date:.abbreviated,time:.omitted)) | CATEGORY=\(r.category.rawValue) | SCOPE=\(r.responsibilityScope.rawValue) | LEVEL=\(r.workLevel.rawValue) | CLAIM=\(r.claimStrength) | TITLE=\(r.title.prefix(160))\nACTION=\(r.actionTaken.prefix(220))\nOUTCOME=\(r.outcome.prefix(180))\nIMPACT=\(r.businessImpact.prefix(180))"
            }.joined(separator:"\n---\n")
            let session=LanguageModelSession(model:model,instructions:"You are a conservative workplace systems analyst. Analyze positive accomplishment records and negative incident records together. Never assume an incident caused an accomplishment unless the records explicitly support that link. Identify correlations as correlations, facts as facts, and inference as inference. Never diagnose people or speculate about motives.")
            let prompt="""
            YEAR: \(year)
            INCIDENT RECORDS: \(incidents.filter{Calendar.current.component(.year,from:$0.occurredAt)==year}.count)
            ACCOMPLISHMENT RECORDS: \(accomplishments.filter{Calendar.current.component(.year,from:$0.date)==year}.count)

            INCIDENT EVIDENCE:
            \(inc.prefix(18000))

            ACCOMPLISHMENT EVIDENCE:
            \(acc.prefix(18000))

            Build a cross-record Work Intelligence report using exactly these headings:
            Executive work narrative
            Recurring friction and failure patterns
            Work created by recurring incidents
            Preventive accomplishments
            Invisible labor and operational load
            Responsibility expansion signals
            Systems that repeatedly require intervention
            Accomplishments that reduced future incident risk
            Incident clusters that deserve structural fixes
            Evidence of organizational dependency
            Where the record is too weak to conclude
            Highest-value questions for management
            Next evidence to capture

            Be skeptical. Do not convert temporal proximity into causation. When a likely relationship exists but is not proven, label it as a hypothesis worth reviewing.
            """
            let result=try await session.respond(to:prompt).content.trimmingCharacters(in:.whitespacesAndNewlines)
            guard !result.isEmpty else { throw AccomplishmentAIError.emptyResponse }
            return result
        }
        #endif
        throw AccomplishmentAIError.unsupportedOS
    }
}
