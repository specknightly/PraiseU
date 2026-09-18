import Foundation

struct RoleBaselineSnapshot: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var effectiveDate: Date = Date()
    var roleTitle: String = ""
    var roleDefinition: String = ""
    var expectedAdjacentPercent: Double = 10
    var notes: String = ""
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    var displayTitle: String {
        let trimmed = roleTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Role baseline" : trimmed
    }
}

struct ResponsibilityDriftDatabase: Codable {
    var schemaVersion: Int = 1
    var baselines: [RoleBaselineSnapshot] = []
}

enum ScopeEvidenceKind: String, CaseIterable, Identifiable, Hashable {
    case accomplishment = "Accomplishment"
    case incident = "Incident"
    case prevention = "Prevention"
    case burden = "Operational Burden"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .accomplishment: return "trophy"
        case .incident: return "exclamationmark.triangle"
        case .prevention: return "shield.checkered"
        case .burden: return "gauge.with.dots.needle.50percent"
        }
    }
}
