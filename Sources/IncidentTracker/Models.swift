import Foundation

struct IncidentDatabase: Codable {
    var schemaVersion: Int = 1
    var incidents: [IncidentRecord] = []
}

struct IncidentRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String = "Untitled Incident"
    var occurredAt: Date = Date()
    var discoveredAt: Date = Date()
    var category: String = "General"
    var tags: [String] = []
    var severity: IncidentSeverity = .moderate
    var status: IncidentStatus = .draft
    var isPinned: Bool = false

    var observedFacts: String = ""
    var contextInterpretation: String = ""
    var impact: String = ""
    var response: String = ""
    var resolution: String = ""
    var followUp: String = ""

    var locationOrSystem: String = ""
    var peopleInvolved: String = ""
    var witnesses: String = ""
    var referenceNumbers: String = ""
    var notes: String = ""

    var aiAnalysis: String = ""
    var neutralFactsDraft: String = ""
    var evidence: [EvidenceItem] = []

    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    var tagsText: String {
        get { tags.joined(separator: ", ") }
        set {
            tags = newValue
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
    }

    var completeness: Double {
        let checks = [
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && title != "Untitled Incident",
            !observedFacts.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !impact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !locationOrSystem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !referenceNumbers.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !evidence.isEmpty
        ]
        return Double(checks.filter { $0 }.count) / Double(checks.count)
    }

    var missingDocumentation: [String] {
        var missing: [String] = []
        if title == "Untitled Incident" || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("descriptive title") }
        if observedFacts.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("observed facts") }
        if impact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("impact") }
        if response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("response taken") }
        if locationOrSystem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append("location or system") }
        if referenceNumbers.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && evidence.isEmpty { missing.append("reference number or evidence") }
        return missing
    }
}

enum IncidentSeverity: String, Codable, CaseIterable, Identifiable, Hashable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case critical = "Critical"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .low: return "info.circle"
        case .moderate: return "exclamationmark.circle"
        case .high: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.octagon"
        }
    }
}

enum IncidentStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case draft = "Draft"
    case open = "Open"
    case monitoring = "Monitoring"
    case resolved = "Resolved"
    case closed = "Closed"

    var id: String { rawValue }
}

struct EvidenceItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var originalName: String
    var storedName: String
    var importedAt: Date = Date()
    var sha256: String
    var note: String = ""
    var byteCount: Int64 = 0
}

enum SidebarSelection: Hashable {
    case all
    case thisYear
    case pinned
    case drafts
    case open
    case resolved
    case timeline
    case reports
    case category(String)
    case tag(String)
}

enum IncidentSort: String, CaseIterable, Identifiable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case severity = "Highest Severity"
    case modified = "Recently Modified"

    var id: String { rawValue }
}

enum DetailTab: String, CaseIterable, Identifiable {
    case details = "Details"
    case evidence = "Evidence"
    case ai = "Incident AI"
    case notes = "Notes"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .details: return "doc.text"
        case .evidence: return "paperclip"
        case .ai: return "sparkles"
        case .notes: return "note.text"
        }
    }
}
