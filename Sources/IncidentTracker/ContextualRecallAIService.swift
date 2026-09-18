import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum ContextualRecallAIService {
    static func analyze(bundle: String) async throws -> String {
        guard bundle.trimmingCharacters(in: .whitespacesAndNewlines).count >= 80 else {
            throw AccomplishmentAIError.insufficientDetail
        }

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard model.isAvailable else { throw AccomplishmentAIError.unavailable }

            let session = LanguageModelSession(
                model: model,
                instructions: """
                You are a conservative workplace context analyst. The supplied text contains a source record and user-inspected recalled history. Retrieval scores are ranking metadata, not evidence of causation. Explicit graph relationships are stronger context than lexical or temporal similarity. Never diagnose people, infer motive, or convert correlation into causation. Distinguish direct support from plausible context and uncertainty.
                """
            )

            let prompt = """
            Review this user-approved contextual recall bundle:

            \(bundle.prefix(14000))

            Use exactly these headings:
            Directly connected history
            Relevant historical context
            Patterns worth reviewing
            What the history does not prove
            Questions to verify
            Best records to inspect next

            Be concise, evidence-aware, and skeptical.
            """

            let text = try await session.respond(to: prompt).content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw AccomplishmentAIError.emptyResponse }
            return text
        }
        #endif

        throw AccomplishmentAIError.unsupportedOS
    }
}
