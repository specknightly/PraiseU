import Foundation

struct AccomplishmentDatabase: Codable {
    var schemaVersion: Int = 1
    var accomplishments: [AccomplishmentRecord] = []
}

struct AccomplishmentRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    var title: String = "Untitled Accomplishment"
    var category: AccomplishmentCategory = .infrastructure
    var tags: [String] = []
    var isPinned: Bool = false
    var isDraft: Bool = true

    var context: String = ""
    var actionTaken: String = ""
    var outcome: String = ""
    var businessImpact: String = ""
    var evidenceNotes: String = ""
    var metrics: String = ""
    var stakeholders: String = ""

    var humanValueAnalysis: String = ""
    var responsibilityScope: ResponsibilityScope = .unclassified
    var scopeInference: String = ""
    var claimStrength: Int = 0
    var workLevel: WorkLevel = .unclassified
    var professionalIntelligence: String = ""
    var evidenceAnalysis: String = ""

    var evidence: [AccomplishmentEvidenceItem] = []

    var tagsText: String {
        get { tags.joined(separator: ", ") }
        set {
            tags = newValue.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
    }

    var completeness: Double {
        let checks = [
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && title != "Untitled Accomplishment",
            !context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !actionTaken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !outcome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !businessImpact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !evidence.isEmpty || !evidenceNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ]
        return Double(checks.filter { $0 }.count) / Double(checks.count)
    }
}

enum AccomplishmentCategory: String, Codable, CaseIterable, Identifiable, Hashable {
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
        case .infrastructure: return "server.rack"
        case .security: return "lock.shield"
        case .support: return "person.crop.circle.badge.checkmark"
        case .automation: return "gearshape.2"
        case .avEvents: return "display.2"
        case .projects: return "shippingbox"
        case .leadership: return "person.3"
        case .documentation: return "doc.text"
        case .reliability: return "waveform.path.ecg"
        case .savings: return "clock.badge.checkmark"
        case .other: return "square.grid.2x2"
        }
    }
}

enum ResponsibilityScope: String, Codable, CaseIterable, Identifiable, Hashable {
    case core = "Core Role"
    case other = "Other / Scope Drift"
    case unclassified = "Unclassified"
    var id: String { rawValue }
}

enum WorkLevel: String, Codable, CaseIterable, Identifiable, Hashable {
    case routine = "Routine"
    case advanced = "Advanced"
    case specialist = "Specialist"
    case projectOwner = "Project Owner"
    case strategic = "Strategic / Leadership"
    case unclassified = "Unclassified"
    var id: String { rawValue }
}

struct AccomplishmentEvidenceItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var originalName: String
    var storedName: String
    var importedAt: Date = Date()
    var sha256: String
    var note: String = ""
    var byteCount: Int64 = 0
}

enum AccomplishmentSidebarSelection: Hashable {
    case all
    case thisYear
    case pinned
    case drafts
    case completed
    case reviewPrep
    case insights
    case intake
    case category(AccomplishmentCategory)
    case tag(String)
}

enum AccomplishmentSort: String, CaseIterable, Identifiable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case modified = "Recently Modified"
    case strongest = "Strongest Evidence"
    var id: String { rawValue }
}

enum AccomplishmentDetailTab: String, CaseIterable, Identifiable {
    case details = "Details"
    case evidence = "Evidence"
    case intelligence = "Value Intelligence"
    case relationships = "Relationships"
    case notes = "Notes"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .details: return "doc.text"
        case .evidence: return "paperclip"
        case .intelligence: return "sparkles"
        case .relationships: return "link"
        case .notes: return "note.text"
        }
    }
}
