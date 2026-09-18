import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum LocalAIError: LocalizedError {
    case unavailable
    case unsupportedOS
    case emptyIncident

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Apple Intelligence is not currently available on this Mac. Check that Apple Intelligence is enabled and its model is ready."
        case .unsupportedOS:
            return "Incident AI requires macOS 26 or later with the Foundation Models framework."
        case .emptyIncident:
            return "Add observed facts before asking Incident AI to analyze the record."
        }
    }
}

enum LocalAIService {
    static func availabilityDescription() -> String {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            if model.isAvailable { return "Apple Intelligence ready" }
            switch model.availability {
            case .available:
                return "Apple Intelligence ready"
            case .unavailable(.appleIntelligenceNotEnabled):
                return "Apple Intelligence is turned off"
            case .unavailable(.deviceNotEligible):
                return "This Mac is not eligible for Apple Intelligence"
            case .unavailable(.modelNotReady):
                return "Apple Intelligence model is not ready yet"
            case .unavailable:
                return "Apple Intelligence unavailable"
            }
        }
        #endif
        return "Incident AI requires macOS 26 or later"
    }

    static func analyze(_ incident: IncidentRecord) async throws -> String {
        guard !incident.observedFacts.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LocalAIError.emptyIncident
        }

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard model.isAvailable else { throw LocalAIError.unavailable }

            let session = LanguageModelSession(model: model, instructions: {
                """
                You are a workplace incident documentation assistant. Your job is to improve documentation quality without inventing facts, assigning blame, making legal conclusions, diagnosing people, or treating speculation as evidence.

                Analyze only the supplied record. Clearly distinguish recorded facts from interpretation. If information is missing, say it is missing. Use concise headings. Focus on chronology, operational impact, response taken, documentation gaps, follow-up questions, recurring-risk signals, and where human judgment or intervention mattered. Never convert an assumption into a fact. Never claim that evidence proves more than the record states.
                """
            })

            let prompt = """
            Analyze this incident record.

            TITLE: \(incident.title)
            OCCURRED: \(incident.occurredAt.formatted(date: .abbreviated, time: .shortened))
            DISCOVERED/RECORDED: \(incident.discoveredAt.formatted(date: .abbreviated, time: .shortened))
            CATEGORY: \(incident.category)
            SEVERITY: \(incident.severity.rawValue)
            STATUS: \(incident.status.rawValue)
            LOCATION OR SYSTEM: \(incident.locationOrSystem)
            PEOPLE INVOLVED: \(incident.peopleInvolved)
            WITNESSES: \(incident.witnesses)
            REFERENCES: \(incident.referenceNumbers)

            OBSERVED FACTS:
            \(incident.observedFacts)

            CONTEXT / INTERPRETATION:
            \(incident.contextInterpretation)

            IMPACT:
            \(incident.impact)

            RESPONSE TAKEN:
            \(incident.response)

            RESOLUTION / OUTCOME:
            \(incident.resolution)

            FOLLOW-UP:
            \(incident.followUp)

            EVIDENCE FILE COUNT: \(incident.evidence.count)
            EVIDENCE NAMES: \(incident.evidence.map(\.originalName).joined(separator: ", "))

            Return these sections:
            1. Incident summary
            2. Timeline and causal sequence actually supported by the record
            3. Operational impact
            4. Response and human judgment
            5. Documentation gaps or ambiguities
            6. Follow-up actions worth considering
            7. Pattern signals to compare against other incidents
            """

            return try await session.respond(to: prompt).content
        }
        #endif
        throw LocalAIError.unsupportedOS
    }

    static func neutralizeFacts(_ incident: IncidentRecord) async throws -> String {
        guard !incident.observedFacts.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LocalAIError.emptyIncident
        }

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard model.isAvailable else { throw LocalAIError.unavailable }

            let session = LanguageModelSession(model: model, instructions: {
                """
                Rewrite workplace incident notes into neutral factual documentation. Preserve every concrete fact and uncertainty. Remove loaded wording, insults, mind-reading, exaggeration, and unsupported causal claims. Do not add facts. Do not make legal or HR conclusions. If the source includes an allegation or interpretation, retain it only when clearly labeled as an allegation or interpretation. Return only the revised factual narrative.
                """
            })
            let prompt = """
            Rewrite the following observed-facts field into concise neutral incident documentation without changing its meaning:

            \(incident.observedFacts)
            """
            return try await session.respond(to: prompt).content
        }
        #endif
        throw LocalAIError.unsupportedOS
    }
}
