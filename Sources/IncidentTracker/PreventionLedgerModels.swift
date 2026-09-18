import Foundation

enum PreventionInterventionType: String, Codable, CaseIterable, Identifiable, Hashable {
    case prevention = "Prevention"
    case mitigation = "Mitigation"
    case earlyDetection = "Early Detection"
    case hardening = "Hardening"
    case automation = "Automation"
    case documentation = "Documentation"
    case training = "Training / Knowledge Transfer"
    case monitoring = "Monitoring"
    case processChange = "Process Change"
    case cleanup = "Technical Debt / Cleanup"

    var id: String { rawValue }
}

enum PreventionEvidenceBasis: String, Codable, CaseIterable, Identifiable, Hashable {
    case measured = "Measured"
    case estimated = "Estimated"
    case inferred = "Inferred"

    var id: String { rawValue }

    var explanation: String {
        switch self {
        case .measured: return "Supported by observed counts, elapsed time, tickets, logs, or other recorded evidence."
        case .estimated: return "A user-supplied estimate with an explicit basis. Treat as an estimate, not a measured fact."
        case .inferred: return "A plausible prevention claim without enough evidence for numeric certainty."
        }
    }
}

struct PreventionInterventionRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var title: String = "Untitled Prevention"
    var type: PreventionInterventionType = .prevention
    var evidenceBasis: PreventionEvidenceBasis = .inferred

    var actionTaken: String = ""
    var riskOrFailureMode: String = ""
    var expectedConsequence: String = ""
    var observedResult: String = ""
    var measurementBasis: String = ""
    var notes: String = ""
    var responsibilityScope: ResponsibilityScope?

    var recurrenceCountAvoided: Int?
    var hoursAvoided: Double?
    var peopleOrSystemsProtected: Int?

    var sourceRecord: WorkGraphNodeRef?
    var linkedNodes: [WorkGraphNodeRef] = []

    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    var hasQuantification: Bool {
        recurrenceCountAvoided != nil || hoursAvoided != nil || peopleOrSystemsProtected != nil
    }

    var quantificationSummary: String {
        var parts: [String] = []
        if let recurrenceCountAvoided { parts.append("\(recurrenceCountAvoided) recurrence\(recurrenceCountAvoided == 1 ? "" : "s") avoided") }
        if let hoursAvoided { parts.append(String(format: "%.1f hours avoided", hoursAvoided)) }
        if let peopleOrSystemsProtected { parts.append("\(peopleOrSystemsProtected) people/systems protected") }
        return parts.isEmpty ? "No numeric claim" : parts.joined(separator: " · ")
    }
}

struct PreventionLedgerDatabase: Codable {
    var schemaVersion: Int = 1
    var records: [PreventionInterventionRecord] = []
}
