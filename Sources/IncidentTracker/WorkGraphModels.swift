import Foundation

enum WorkGraphNodeKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case incident = "Incident"
    case accomplishment = "Accomplishment"
    case evidence = "Evidence"
    case person = "Person"
    case system = "System"
    case project = "Project"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .incident: return "exclamationmark.triangle"
        case .accomplishment: return "trophy"
        case .evidence: return "paperclip"
        case .person: return "person"
        case .system: return "server.rack"
        case .project: return "shippingbox"
        }
    }

    var isNamedEntity: Bool {
        switch self {
        case .person, .system, .project: return true
        case .incident, .accomplishment, .evidence: return false
        }
    }
}

struct WorkGraphNodeRef: Codable, Hashable {
    var kind: WorkGraphNodeKind
    var nodeID: UUID
    var parentID: UUID?

    init(kind: WorkGraphNodeKind, nodeID: UUID, parentID: UUID? = nil) {
        self.kind = kind
        self.nodeID = nodeID
        self.parentID = parentID
    }

    var stableKey: String {
        [kind.rawValue, parentID?.uuidString ?? "root", nodeID.uuidString].joined(separator: ":")
    }
}

struct WorkGraphEntity: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var kind: WorkGraphNodeKind
    var name: String
    var notes: String = ""
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    var nodeRef: WorkGraphNodeRef { WorkGraphNodeRef(kind: kind, nodeID: id) }
}

enum WorkGraphRelationshipKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case relatedTo = "Related To"
    case involves = "Involves"
    case affects = "Affects"
    case supports = "Supports"
    case evidenceFor = "Evidence For"
    case partOf = "Part Of"
    case workedOn = "Worked On"
    case prevented = "Prevented / Reduced Risk"
    case respondedTo = "Responded To"
    case resolved = "Resolved / Helped Resolve"
    case dependsOn = "Depends On"
    case stakeholder = "Stakeholder"

    var id: String { rawValue }
}

struct WorkGraphLink: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var source: WorkGraphNodeRef
    var target: WorkGraphNodeRef
    var relationship: WorkGraphRelationshipKind = .relatedTo
    var note: String = ""
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    func touches(_ node: WorkGraphNodeRef) -> Bool { source == node || target == node }

    func otherNode(than node: WorkGraphNodeRef) -> WorkGraphNodeRef? {
        if source == node { return target }
        if target == node { return source }
        return nil
    }
}

struct WorkGraphDatabase: Codable {
    var schemaVersion: Int = 1
    var entities: [WorkGraphEntity] = []
    var links: [WorkGraphLink] = []
}

struct WorkGraphCatalogNode: Identifiable, Hashable {
    let ref: WorkGraphNodeRef
    let title: String
    let subtitle: String
    let date: Date?

    var id: String { ref.stableKey }
    var kind: WorkGraphNodeKind { ref.kind }
    var searchableText: String { "\(title) \(subtitle) \(kind.rawValue)".lowercased() }
}
