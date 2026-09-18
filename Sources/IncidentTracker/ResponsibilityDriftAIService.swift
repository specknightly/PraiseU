import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum ResponsibilityDriftAIService {
    static func analyze(report: ResponsibilityDriftReport) async throws -> String {
        let packet = ResponsibilityDriftExportService.markdown(report: report)
        guard report.classifiedEvidence.count >= 2 else {
            throw AccomplishmentAIError.insufficientDetail
        }

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard model.isAvailable else { throw AccomplishmentAIError.unavailable }

            let session = LanguageModelSession(
                model: model,
                instructions: """
                You are a conservative professional-evidence analyst. Analyze responsibility drift without inventing duties, organizational policy, compensation bands, peer performance, manager motives, or formal ownership. Treat scope labels as user classifications that require corroboration. A record-count percentage is an evidence mix, not a time-allocation measurement. Keep measured and estimated burden separate. Repeated system/project linkage is a de facto ownership signal, not proof of official accountability. Do not recommend a specific salary or compensation outcome. Build evidence-backed preparation material and identify counterarguments and gaps.
                """
            )

            let prompt = """
            Review this Responsibility Drift evidence packet:

            \(packet.prefix(24000))

            Use exactly these headings:
            Role baseline
            Documented divergence from baseline
            Drift over time
            Repeated systems and projects
            Higher-level work outside baseline
            Operational burden outside baseline
            Evidence for title or role-scope discussion
            Evidence for staffing discussion
            Evidence for compensation or promotion discussion
            Strongest skeptical counterarguments
            What the record does not prove
            Missing evidence to capture next
            Review-room talking points

            Be concise, skeptical, and source-bound. Distinguish facts, user classifications, measured values, estimates, and inference.
            """

            let text = try await session.respond(to: prompt).content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw AccomplishmentAIError.emptyResponse }
            return text
        }
        #endif

        throw AccomplishmentAIError.unsupportedOS
    }
}
