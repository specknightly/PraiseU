import Foundation

enum WorkIntelligenceSourceKind: String, CaseIterable, Hashable {
    case incident = "Incident"
    case accomplishment = "Accomplishment"
    case prevention = "Prevention"
    case burden = "Operational Burden"
    case evidence = "Evidence"
    case person = "Person"
    case system = "System"
    case project = "Project"
    case roleBaseline = "Role Baseline"

    var symbol: String {
        switch self {
        case .incident: return "exclamationmark.triangle"
        case .accomplishment: return "trophy"
        case .prevention: return "shield.checkered"
        case .burden: return "gauge.with.dots.needle.50percent"
        case .evidence: return "paperclip"
        case .person: return "person"
        case .system: return "server.rack"
        case .project: return "shippingbox"
        case .roleBaseline: return "arrow.triangle.branch"
        }
    }
}

struct WorkIntelligenceSource: Identifiable, Hashable {
    let id: String
    let kind: WorkIntelligenceSourceKind
    let title: String
    let subtitle: String
    let date: Date?
    let score: Double
    let reasons: [String]
    let contextText: String
    let nodeRef: WorkGraphNodeRef?

    var confidenceLabel: String {
        if score >= 140 { return "Direct" }
        if score >= 90 { return "Strong" }
        if score >= 45 { return "Relevant" }
        return "Supporting"
    }
}

struct WorkIntelligenceTurn: Identifiable, Hashable {
    let id: UUID
    let question: String
    let answer: String
    let sources: [WorkIntelligenceSource]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        question: String,
        answer: String,
        sources: [WorkIntelligenceSource],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.question = question
        self.answer = answer
        self.sources = sources
        self.createdAt = createdAt
    }
}

struct WorkIntelligencePreset: Identifiable, Hashable {
    let id: String
    let title: String
    let prompt: String
    let symbol: String

    static let defaults: [WorkIntelligencePreset] = [
        .init(
            id: "promotion",
            title: "Promotion evidence",
            prompt: "What are my strongest evidence-backed accomplishments for a promotion or expanded-role discussion?",
            symbol: "trophy"
        ),
        .init(
            id: "defense",
            title: "Incident defense",
            prompt: "What documented incident history would be most relevant if my work or response were questioned?",
            symbol: "shield"
        ),
        .init(
            id: "burden",
            title: "Operational burden",
            prompt: "Where is my recorded operational burden going, and what patterns are supported by the evidence?",
            symbol: "gauge.with.dots.needle.50percent"
        ),
        .init(
            id: "prevention",
            title: "Preventive value",
            prompt: "What preventive or intervention work is best supported, and what avoided burden is measured versus estimated?",
            symbol: "shield.checkered"
        ),
        .init(
            id: "drift",
            title: "Responsibility drift",
            prompt: "What evidence supports that my real responsibilities have expanded beyond my role baseline?",
            symbol: "arrow.triangle.branch"
        ),
        .init(
            id: "systems",
            title: "Systems needing me",
            prompt: "Which systems or projects repeatedly depend on my intervention, and what does the record actually support?",
            symbol: "server.rack"
        )
    ]
}
