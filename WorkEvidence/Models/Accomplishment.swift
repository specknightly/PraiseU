import Foundation
import SwiftData

@Model
final class Accomplishment {
    @Attribute(.unique) var id: UUID
    var date: Date
    var createdAt: Date
    var updatedAt: Date
    var title: String
    var categoryRaw: String
    var context: String
    var actionTaken: String
    var outcome: String
    var businessImpact: String
    var evidenceNotes: String
    var metrics: String
    var stakeholders: String
    var tagsText: String
    var isPinned: Bool
    var humanValueAnalysis: String?
    var humanValueGeneratedAt: Date?
    var responsibilityScopeRaw: String = ResponsibilityScope.unclassified.rawValue
    var scopeInference: String?
    var scopeInferenceGeneratedAt: Date?
    var claimStrength: Int?
    var workLevelRaw: String?
    var professionalIntelligence: String?
    var professionalIntelligenceGeneratedAt: Date?
    var evidenceAnalysis: String?
    var evidenceAnalysisGeneratedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \EvidenceAttachment.entry)
    var attachments: [EvidenceAttachment]

    init(
        id: UUID = UUID(),
        date: Date = .now,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        title: String = "",
        category: AccomplishmentCategory = .infrastructure,
        context: String = "",
        actionTaken: String = "",
        outcome: String = "",
        businessImpact: String = "",
        evidenceNotes: String = "",
        metrics: String = "",
        stakeholders: String = "",
        tagsText: String = "",
        isPinned: Bool = false,
        humanValueAnalysis: String? = nil,
        humanValueGeneratedAt: Date? = nil,
        attachments: [EvidenceAttachment] = []
    ) {
        self.id = id
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.categoryRaw = category.rawValue
        self.context = context
        self.actionTaken = actionTaken
        self.outcome = outcome
        self.businessImpact = businessImpact
        self.evidenceNotes = evidenceNotes
        self.metrics = metrics
        self.stakeholders = stakeholders
        self.tagsText = tagsText
        self.isPinned = isPinned
        self.humanValueAnalysis = humanValueAnalysis
        self.humanValueGeneratedAt = humanValueGeneratedAt
        self.attachments = attachments
    }

    var responsibilityScope: ResponsibilityScope {
        get { ResponsibilityScope(rawValue: responsibilityScopeRaw) ?? .unclassified }
        set { responsibilityScopeRaw = newValue.rawValue }
    }

    var workLevel: WorkLevel {
        get { WorkLevel(rawValue: workLevelRaw ?? "") ?? .unclassified }
        set { workLevelRaw = newValue.rawValue }
    }

    var category: AccomplishmentCategory {
        get { AccomplishmentCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var tags: [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var searchBlob: String {
        [title, categoryRaw, context, actionTaken, outcome, businessImpact, evidenceNotes, metrics, stakeholders, tagsText, humanValueAnalysis ?? "", scopeInference ?? "", responsibilityScopeRaw, professionalIntelligence ?? "", evidenceAnalysis ?? "", workLevelRaw ?? ""]
            .joined(separator: " ")
            .lowercased()
    }
}

enum AccomplishmentCategory: String, CaseIterable, Identifiable {
    case infrastructure = "Infrastructure"
    case security = "Security"
    case support = "User Support"
    case automation = "Automation"
    case avEvents = "A/V & Events"
    case projects = "Projects"
    case leadership = "Leadership"
    case documentation = "Documentation"
    case reliability = "Reliability"
    case savings = "Cost / Time Savings"
    case other = "Other"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .infrastructure: "server.rack"
        case .security: "lock.shield"
        case .support: "person.crop.circle.badge.checkmark"
        case .automation: "gearshape.2"
        case .avEvents: "display.2"
        case .projects: "shippingbox"
        case .leadership: "person.3"
        case .documentation: "doc.text"
        case .reliability: "waveform.path.ecg"
        case .savings: "clock.badge.checkmark"
        case .other: "square.grid.2x2"
        }
    }
}


enum ResponsibilityScope: String, CaseIterable, Identifiable, Sendable {
    case core = "Core Role"
    case other = "Other / Scope Drift"
    case unclassified = "Unclassified"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .core: "checkmark.seal"
        case .other: "arrow.up.right.circle"
        case .unclassified: "questionmark.circle"
        }
    }
}


enum WorkLevel: String, CaseIterable, Identifiable, Sendable {
    case routine = "Routine"
    case advanced = "Advanced"
    case specialist = "Specialist"
    case projectOwner = "Project Owner"
    case strategic = "Strategic / Leadership"
    case unclassified = "Unclassified"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .routine: "wrench.and.screwdriver"
        case .advanced: "brain.head.profile"
        case .specialist: "star.circle"
        case .projectOwner: "person.badge.key"
        case .strategic: "scope"
        case .unclassified: "questionmark.circle"
        }
    }
}
