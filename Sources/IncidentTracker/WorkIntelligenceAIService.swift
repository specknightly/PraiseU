import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum WorkIntelligenceAIService {
    static func answer(
        question: String,
        sources: [WorkIntelligenceSource],
        priorTurns: [WorkIntelligenceTurn]
    ) async throws -> String {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3, !sources.isEmpty else {
            throw AccomplishmentAIError.insufficientDetail
        }

        let packet = WorkIntelligenceRetrievalEngine.packet(
            question: trimmed,
            sources: sources,
            maxCharacters: 22000
        )

        let conversation = priorTurns.suffix(4).map { turn in
            """
            USER: \(turn.question.prefix(700))
            ASSISTANT SUMMARY: \(turn.answer.prefix(1400))
            """
        }.joined(separator: "\n---\n")

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard model.isAvailable else { throw AccomplishmentAIError.unavailable }

            let session = LanguageModelSession(
                model: model,
                instructions: """
                You are Entropy Shield Work Intelligence, a conservative local professional-evidence analyst.

                EVIDENCE RULES:
                - The current SOURCE PACKET is the only evidence you may use for factual claims.
                - Cite factual claims inline with the supplied source labels, for example [S1] or [S2][S5].
                - Never invent a citation label.
                - Retrieval scores rank relevance; they are not proof, confidence in truth, causation, or formal ownership.
                - Explicit Work Graph relationships are context. Do not convert them into motive, causation, formal accountability, or organizational policy unless a source explicitly establishes that fact.
                - Keep observed facts, user classifications, measurements, estimates, and inference distinct.
                - Evidence attachment metadata proves the recorded file name/hash/import metadata only; it does not reveal unprovided file contents.
                - Measured and estimated burden must stay separate.
                - Prevention expected consequences are risk statements, not events that definitely would have happened.
                - Scope labels are user classifications and should be corroborated for formal employment claims.
                - Do not diagnose people, infer mental state, infer motives, judge competence, or make health conclusions.
                - Do not invent compensation bands, monetary savings, peer comparisons, company policy, or legal conclusions.
                - If the sources do not support an answer, say that plainly and identify what evidence would be needed.

                CONVERSATION RULES:
                - Prior conversation is provided only to understand follow-up intent. It is not evidence.
                - Source labels reset on every answer. Cite only labels from the current packet.
                - Answer the user's actual question before offering analysis.
                """
            )

            let prompt = """
            PRIOR CONVERSATION FOR FOLLOW-UP CONTEXT ONLY:
            \(conversation.isEmpty ? "None." : conversation.prefix(6500))

            CURRENT SOURCE PACKET:
            \(packet)

            CURRENT QUESTION:
            \(trimmed)

            Answer using exactly these headings:
            Direct answer
            What the record supports
            Interpretation
            What the record does not prove
            Useful next questions

            Requirements:
            - Keep the answer concise enough to use during a real work or review conversation.
            - Put source citations immediately after the factual statement they support.
            - Under Interpretation, label hypotheses or pattern interpretations as interpretation.
            - Under What the record does not prove, include important limitations rather than boilerplate.
            - Under Useful next questions, suggest at most four evidence-seeking follow-ups.
            """

            let response = try await session.respond(to: prompt).content
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !response.isEmpty else { throw AccomplishmentAIError.emptyResponse }
            return response
        }
        #endif

        throw AccomplishmentAIError.unsupportedOS
    }
}
