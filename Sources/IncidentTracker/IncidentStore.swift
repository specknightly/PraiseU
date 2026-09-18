import AppKit
import Combine
import CryptoKit
import Foundation

@MainActor
final class IncidentStore: ObservableObject {
    @Published private(set) var incidents: [IncidentRecord] = []
    @Published var lastError: String?

    private let fileManager = FileManager.default
    private var rootURL: URL { WorkRecordStorage.rootURL }
    private var recordsURL: URL { WorkRecordStorage.incidentsURL }
    private var evidenceRootURL: URL { WorkRecordStorage.incidentEvidenceURL }
    private var backupsURL: URL { WorkRecordStorage.incidentBackupsURL }

    init() {
        prepareStorage()
        load()
    }

    func reloadFromStorage() {
        incidents = []
        prepareStorage()
        load()
    }

    var totalCount: Int { incidents.count }
    var thisYearCount: Int {
        incidents.filter { Calendar.current.isDate($0.occurredAt, equalTo: Date(), toGranularity: .year) }.count
    }
    var pinnedCount: Int { incidents.filter(\.isPinned).count }
    var openCount: Int { incidents.filter { [.open, .monitoring].contains($0.status) }.count }
    var resolvedCount: Int { incidents.filter { [.resolved, .closed].contains($0.status) }.count }
    var aiEnrichedCount: Int { incidents.filter { !$0.aiAnalysis.isEmpty }.count }

    var categories: [String] {
        Array(Set(incidents.map(\.category).filter { !$0.isEmpty })).sorted()
    }

    var tags: [String] {
        Array(Set(incidents.flatMap(\.tags))).sorted()
    }

    func incident(id: UUID) -> IncidentRecord? {
        incidents.first { $0.id == id }
    }

    @discardableResult
    func createIncident() -> IncidentRecord {
        var record = IncidentRecord()
        record.status = .draft
        record.category = "General"
        record.modifiedAt = Date()
        incidents.insert(record, at: 0)
        persist()
        return record
    }

    func save(_ record: IncidentRecord) {
        var updated = record
        updated.modifiedAt = Date()
        if let index = incidents.firstIndex(where: { $0.id == updated.id }) {
            incidents[index] = updated
        } else {
            incidents.insert(updated, at: 0)
        }
        persist()
    }

    func delete(_ id: UUID) {
        incidents.removeAll { $0.id == id }
        let dir = evidenceDirectory(for: id)
        try? fileManager.removeItem(at: dir)
        persist()
    }

    func importEvidence(urls: [URL], into incidentID: UUID) throws {
        guard var record = incident(id: incidentID) else { return }
        let dir = evidenceDirectory(for: incidentID)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)

        for source in urls {
            let scoped = source.startAccessingSecurityScopedResource()
            defer { if scoped { source.stopAccessingSecurityScopedResource() } }

            let data = try Data(contentsOf: source)
            let hash = Self.sha256(data)
            let safeName = source.lastPathComponent.replacingOccurrences(of: "/", with: "-")
            let storedName = "\(UUID().uuidString)-\(safeName)"
            let destination = dir.appendingPathComponent(storedName)
            try data.write(to: destination, options: .atomic)

            let evidence = EvidenceItem(
                originalName: source.lastPathComponent,
                storedName: storedName,
                importedAt: Date(),
                sha256: hash,
                note: "",
                byteCount: Int64(data.count)
            )
            record.evidence.append(evidence)
        }

        save(record)
    }

    func removeEvidence(_ evidenceID: UUID, from incidentID: UUID) {
        guard var record = incident(id: incidentID),
              let item = record.evidence.first(where: { $0.id == evidenceID }) else { return }
        try? fileManager.removeItem(at: evidenceURL(for: item, incidentID: incidentID))
        record.evidence.removeAll { $0.id == evidenceID }
        save(record)
    }

    func updateEvidenceNote(_ evidenceID: UUID, incidentID: UUID, note: String) {
        guard var record = incident(id: incidentID),
              let index = record.evidence.firstIndex(where: { $0.id == evidenceID }) else { return }
        record.evidence[index].note = note
        save(record)
    }

    func evidenceURL(for item: EvidenceItem, incidentID: UUID) -> URL {
        evidenceDirectory(for: incidentID).appendingPathComponent(item.storedName)
    }

    func verifyEvidence(_ item: EvidenceItem, incidentID: UUID) -> Bool {
        let url = evidenceURL(for: item, incidentID: incidentID)
        guard let data = try? Data(contentsOf: url) else { return false }
        return Self.sha256(data) == item.sha256
    }

    func filtered(selection: SidebarSelection, searchText: String, sort: IncidentSort) -> [IncidentRecord] {
        var result = incidents.filter { record in
            switch selection {
            case .all: return true
            case .thisYear: return Calendar.current.isDate(record.occurredAt, equalTo: Date(), toGranularity: .year)
            case .pinned: return record.isPinned
            case .drafts: return record.status == .draft
            case .open: return [.open, .monitoring].contains(record.status)
            case .resolved: return [.resolved, .closed].contains(record.status)
            case .category(let category): return record.category == category
            case .tag(let tag): return record.tags.contains(tag)
            case .timeline, .reports: return true
            }
        }

        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !needle.isEmpty {
            result = result.filter { record in
                [record.title, record.category, record.tagsText, record.observedFacts, record.impact,
                 record.response, record.locationOrSystem, record.peopleInvolved, record.referenceNumbers]
                    .joined(separator: " ")
                    .lowercased()
                    .contains(needle)
            }
        }

        switch sort {
        case .newest: result.sort { $0.occurredAt > $1.occurredAt }
        case .oldest: result.sort { $0.occurredAt < $1.occurredAt }
        case .modified: result.sort { $0.modifiedAt > $1.modifiedAt }
        case .severity:
            let rank: [IncidentSeverity: Int] = [.critical: 4, .high: 3, .moderate: 2, .low: 1]
            result.sort { (rank[$0.severity] ?? 0, $0.occurredAt) > (rank[$1.severity] ?? 0, $1.occurredAt) }
        }
        return result
    }

    private func prepareStorage() {
        do {
            try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: evidenceRootURL, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: backupsURL, withIntermediateDirectories: true)
        } catch {
            lastError = "Could not prepare local storage: \(error.localizedDescription)"
        }
    }

    private func evidenceDirectory(for incidentID: UUID) -> URL {
        evidenceRootURL.appendingPathComponent(incidentID.uuidString, isDirectory: true)
    }

    private func load() {
        guard fileManager.fileExists(atPath: recordsURL.path) else { return }
        do {
            let data = try Data(contentsOf: recordsURL)
            let decoder = JSONDecoder.incidentDecoder
            if let database = try? decoder.decode(IncidentDatabase.self, from: data) {
                incidents = database.incidents
            } else {
                // Backward-compatible fallback for the earliest prototype format.
                incidents = try decoder.decode([IncidentRecord].self, from: data)
            }
        } catch {
            lastError = "Could not load incidents: \(error.localizedDescription)"
        }
    }

    private func persist() {
        do {
            createBackupIfPossible()
            let database = IncidentDatabase(schemaVersion: 1, incidents: incidents)
            let data = try JSONEncoder.incidentEncoder.encode(database)
            try data.write(to: recordsURL, options: .atomic)
            pruneBackups()
        } catch {
            lastError = "Could not save incidents: \(error.localizedDescription)"
        }
    }

    private func createBackupIfPossible() {
        guard fileManager.fileExists(atPath: recordsURL.path) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let backup = backupsURL.appendingPathComponent("incidents-\(formatter.string(from: Date())).json")
        try? fileManager.copyItem(at: recordsURL, to: backup)
    }

    private func pruneBackups(keeping limit: Int = 25) {
        guard let files = try? fileManager.contentsOfDirectory(
            at: backupsURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        let sorted = files.sorted { lhs, rhs in
            let l = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let r = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return l > r
        }
        for old in sorted.dropFirst(limit) {
            try? fileManager.removeItem(at: old)
        }
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

extension JSONEncoder {
    static var incidentEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var incidentDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
