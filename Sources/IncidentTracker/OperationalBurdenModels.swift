import Foundation

enum OperationalBurdenKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case interruption = "Interruption / Context Switch"
    case incidentResponse = "Incident Response"
    case reactiveSupport = "Reactive Support"
    case afterHours = "After-Hours Work"
    case coordination = "Coordination / Follow-up"
    case meeting = "Meeting / Communication"
    case repeatWork = "Repeat Work / Rework"
    case maintenance = "Maintenance / Caretaking"
    case escalation = "Escalation / Ownership Gap"
    case vendor = "Vendor / Dependency"
    case administrative = "Administrative / Process"
    case other = "Other"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .interruption: return "arrow.triangle.2.circlepath"
        case .incidentResponse: return "exclamationmark.triangle"
        case .reactiveSupport: return "lifepreserver"
        case .afterHours: return "moon.stars"
        case .coordination: return "person.2"
        case .meeting: return "bubble.left.and.bubble.right"
        case .repeatWork: return "repeat"
        case .maintenance: return "wrench.and.screwdriver"
        case .escalation: return "arrow.up.right"
        case .vendor: return "building.2"
        case .administrative: return "doc.text"
        case .other: return "ellipsis.circle"
        }
    }
}

enum OperationalBurdenEvidenceBasis: String, Codable, CaseIterable, Identifiable, Hashable {
    case measured = "Measured"
    case estimated = "Estimated"

    var id: String { rawValue }

    var explanation: String {
        switch self {
        case .measured:
            return "Time or counts are based on a timer, calendar, ticket/log timestamps, or another recorded source."
        case .estimated:
            return "Time or counts are a good-faith estimate. Keep the basis so the estimate remains distinguishable from a measurement."
        }
    }
}

struct OperationalBurdenRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var title: String = "Untitled Burden"
    var kind: OperationalBurdenKind = .interruption
    var evidenceBasis: OperationalBurdenEvidenceBasis = .estimated

    var description: String = ""
    var triggerOrSource: String = ""
    var impactOnPlannedWork: String = ""
    var measurementBasis: String = ""
    var notes: String = ""

    /// Active minutes consumed by the work itself.
    var durationMinutes: Int?
    /// Additional minutes needed to regain working context. Not included in durationMinutes.
    var recoveryMinutes: Int?
    /// Portion of active duration performed outside normal working hours. Do not add to total burden twice.
    var afterHoursMinutes: Int?
    var interruptionCount: Int?
    var contextSwitchCount: Int?

    /// Subjective self-report scales; not objective productivity or health measures.
    var cognitiveLoad: Int = 3
    var coordinationLoad: Int = 0

    var sourceRecord: WorkGraphNodeRef?
    var linkedNodes: [WorkGraphNodeRef] = []

    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    var activeMinutes: Int { max(0, durationMinutes ?? 0) }
    var recoveryBurdenMinutes: Int { max(0, recoveryMinutes ?? 0) }
    var totalBurdenMinutes: Int { activeMinutes + recoveryBurdenMinutes }
    var safeAfterHoursMinutes: Int { min(max(0, afterHoursMinutes ?? 0), activeMinutes) }
    var safeInterruptionCount: Int { max(0, interruptionCount ?? 0) }
    var safeContextSwitchCount: Int { max(0, contextSwitchCount ?? 0) }

    var timeSummary: String {
        guard totalBurdenMinutes > 0 else { return "No time captured" }
        let hours = Double(totalBurdenMinutes) / 60.0
        return String(format: "%.1f hrs burden", hours)
    }
}

struct OperationalBurdenDatabase: Codable {
    var schemaVersion: Int = 1
    var records: [OperationalBurdenRecord] = []
}

struct OperationalBurdenKindSummary: Identifiable, Hashable {
    let kind: OperationalBurdenKind
    let measuredMinutes: Int
    let estimatedMinutes: Int
    let recordCount: Int

    var id: String { kind.rawValue }
    var totalMinutes: Int { measuredMinutes + estimatedMinutes }
}
