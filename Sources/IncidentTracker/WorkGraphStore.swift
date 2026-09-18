import Combine
import Foundation

@MainActor
final class WorkGraphStore: ObservableObject {
    @Published private(set) var entities: [WorkGraphEntity] = []
    @Published private(set) var links: [WorkGraphLink] = []
    @Published var lastError: String?

    private let fileManager = FileManager.default
    private var recordsURL: URL { WorkRecordStorage.workGraphURL }
    private var backupsURL: URL { WorkRecordStorage.workGraphBackupsURL }

    init() {
        prepareStorage()
        load()
    }

    func reloadFromStorage() {
        entities = []
        links = []
        prepareStorage()
        load()
    }

    @discardableResult
    func createEntity(kind: WorkGraphNodeKind, name: String, notes: String = "") -> WorkGraphEntity? {
        guard kind.isNamedEntity else { return nil }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        var entity = WorkGraphEntity(kind: kind, name: trimmedName, notes: notes)
        entity.modifiedAt = Date()
        entities.append(entity)
        sortEntities()
        persist()
        return entity
    }

    func saveEntity(_ entity: WorkGraphEntity) {
        guard entity.kind.isNamedEntity else { return }
        var updated = entity
        updated.name = updated.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !updated.name.isEmpty else { return }
        updated.modifiedAt = Date()
        if let index = entities.firstIndex(where: { $0.id == updated.id }) {
            entities[index] = updated
        } else {
            entities.append(updated)
        }
        sortEntities()
        persist()
    }

    func deleteEntity(_ id: UUID) {
        guard let entity = entities.first(where: { $0.id == id }) else { return }
        let ref = entity.nodeRef
        entities.removeAll { $0.id == id }
        links.removeAll { $0.touches(ref) }
        persist()
    }

    @discardableResult
    func createLink(
        source: WorkGraphNodeRef,
        target: WorkGraphNodeRef,
        relationship: WorkGraphRelationshipKind,
        note: String = ""
    ) -> WorkGraphLink? {
        guard source != target else { return nil }

        if let index = links.firstIndex(where: {
            $0.source == source && $0.target == target && $0.relationship == relationship
        }) {
            links[index].note = note
            links[index].modifiedAt = Date()
            persist()
            return links[index]
        }

        let link = WorkGraphLink(source: source, target: target, relationship: relationship, note: note)
        links.append(link)
        persist()
        return link
    }

    func deleteLink(_ id: UUID) {
        links.removeAll { $0.id == id }
        persist()
    }

    func links(for node: WorkGraphNodeRef) -> [WorkGraphLink] {
        links.filter { $0.touches(node) }.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    func relationshipCount(for node: WorkGraphNodeRef) -> Int {
        links.reduce(into: 0) { count, link in
            if link.touches(node) { count += 1 }
        }
    }

    private func prepareStorage() {
        do {
            try WorkRecordStorage.prepareRoot()
            try fileManager.createDirectory(at: backupsURL, withIntermediateDirectories: true)
        } catch {
            lastError = "Could not prepare Work Graph storage: \(error.localizedDescription)"
        }
    }

    private func load() {
        guard fileManager.fileExists(atPath: recordsURL.path) else { return }
        do {
            let data = try Data(contentsOf: recordsURL)
            let database = try JSONDecoder.incidentDecoder.decode(WorkGraphDatabase.self, from: data)
            entities = database.entities
            links = database.links
            sortEntities()
        } catch {
            lastError = "Could not load Work Graph: \(error.localizedDescription)"
        }
    }

    private func persist() {
        do {
            createBackupIfPossible()
            let database = WorkGraphDatabase(schemaVersion: 1, entities: entities, links: links)
            let data = try JSONEncoder.incidentEncoder.encode(database)
            try data.write(to: recordsURL, options: .atomic)
            pruneBackups()
        } catch {
            lastError = "Could not save Work Graph: \(error.localizedDescription)"
        }
    }

    private func createBackupIfPossible() {
        guard fileManager.fileExists(atPath: recordsURL.path) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let backup = backupsURL.appendingPathComponent("work-graph-\(formatter.string(from: Date())).json")
        try? fileManager.copyItem(at: recordsURL, to: backup)
    }

    private func pruneBackups(keeping limit: Int = 25) {
        guard let files = try? fileManager.contentsOfDirectory(
            at: backupsURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        let sorted = files.sorted { lhs, rhs in
            let left = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let right = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return left > right
        }
        for old in sorted.dropFirst(limit) {
            try? fileManager.removeItem(at: old)
        }
    }

    private func sortEntities() {
        entities.sort {
            if $0.kind.rawValue != $1.kind.rawValue { return $0.kind.rawValue < $1.kind.rawValue }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}
