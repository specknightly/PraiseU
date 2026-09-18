import AppKit
import Combine
import CryptoKit
import Foundation

@MainActor
final class AccomplishmentStore: ObservableObject {
    @Published private(set) var accomplishments: [AccomplishmentRecord] = []
    @Published var lastError: String?

    private let fileManager = FileManager.default
    private var rootURL: URL { WorkRecordStorage.accomplishmentsRootURL }
    private var recordsURL: URL { WorkRecordStorage.accomplishmentsURL }
    private var evidenceRootURL: URL { WorkRecordStorage.accomplishmentEvidenceURL }
    private var backupsURL: URL { WorkRecordStorage.accomplishmentBackupsURL }

    init() {
        prepareStorage()
        load()
    }

    func reloadFromStorage() {
        accomplishments = []
        prepareStorage()
        load()
    }

    var totalCount: Int { accomplishments.count }
    var thisYearCount: Int { accomplishments.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .year) }.count }
    var pinnedCount: Int { accomplishments.filter(\.isPinned).count }
    var draftCount: Int { accomplishments.filter(\.isDraft).count }
    var completedCount: Int { accomplishments.filter { !$0.isDraft }.count }
    var evidenceCount: Int { accomplishments.reduce(0) { $0 + $1.evidence.count } }
    var enrichedCount: Int { accomplishments.filter { !$0.humanValueAnalysis.isEmpty || !$0.professionalIntelligence.isEmpty }.count }

    var tags: [String] { Array(Set(accomplishments.flatMap(\.tags))).sorted() }

    func accomplishment(id: UUID) -> AccomplishmentRecord? { accomplishments.first { $0.id == id } }

    @discardableResult
    func createAccomplishment() -> AccomplishmentRecord {
        var record = AccomplishmentRecord()
        record.modifiedAt = Date()
        accomplishments.insert(record, at: 0)
        persist()
        return record
    }

    func save(_ record: AccomplishmentRecord) {
        var updated = record
        updated.modifiedAt = Date()
        if let index = accomplishments.firstIndex(where: { $0.id == updated.id }) {
            accomplishments[index] = updated
        } else {
            accomplishments.insert(updated, at: 0)
        }
        persist()
    }

    func delete(_ id: UUID) {
        accomplishments.removeAll { $0.id == id }
        try? fileManager.removeItem(at: evidenceDirectory(for: id))
        persist()
    }

    func importEvidence(urls: [URL], into accomplishmentID: UUID) throws {
        guard var record = accomplishment(id: accomplishmentID) else { return }
        let dir = evidenceDirectory(for: accomplishmentID)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        for source in urls {
            let scoped = source.startAccessingSecurityScopedResource()
            defer { if scoped { source.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: source)
            let safeName = source.lastPathComponent.replacingOccurrences(of: "/", with: "-")
            let storedName = "\(UUID().uuidString)-\(safeName)"
            try data.write(to: dir.appendingPathComponent(storedName), options: .atomic)
            record.evidence.append(AccomplishmentEvidenceItem(
                originalName: source.lastPathComponent,
                storedName: storedName,
                sha256: Self.sha256(data),
                byteCount: Int64(data.count)
            ))
        }
        save(record)
    }

    func removeEvidence(_ evidenceID: UUID, from accomplishmentID: UUID) {
        guard var record = accomplishment(id: accomplishmentID),
              let item = record.evidence.first(where: { $0.id == evidenceID }) else { return }
        try? fileManager.removeItem(at: evidenceURL(for: item, accomplishmentID: accomplishmentID))
        record.evidence.removeAll { $0.id == evidenceID }
        save(record)
    }

    func updateEvidenceNote(_ evidenceID: UUID, accomplishmentID: UUID, note: String) {
        guard var record = accomplishment(id: accomplishmentID),
              let index = record.evidence.firstIndex(where: { $0.id == evidenceID }) else { return }
        record.evidence[index].note = note
        save(record)
    }

    func evidenceURL(for item: AccomplishmentEvidenceItem, accomplishmentID: UUID) -> URL {
        evidenceDirectory(for: accomplishmentID).appendingPathComponent(item.storedName)
    }

    func verifyEvidence(_ item: AccomplishmentEvidenceItem, accomplishmentID: UUID) -> Bool {
        guard let data = try? Data(contentsOf: evidenceURL(for: item, accomplishmentID: accomplishmentID)) else { return false }
        return Self.sha256(data) == item.sha256
    }

    func filtered(selection: AccomplishmentSidebarSelection, searchText: String, sort: AccomplishmentSort) -> [AccomplishmentRecord] {
        var result = accomplishments.filter { record in
            switch selection {
            case .all: return true
            case .thisYear: return Calendar.current.isDate(record.date, equalTo: Date(), toGranularity: .year)
            case .pinned: return record.isPinned
            case .drafts: return record.isDraft
            case .completed: return !record.isDraft
            case .reviewPrep, .insights, .intake: return true
            case .category(let category): return record.category == category
            case .tag(let tag): return record.tags.contains(tag)
            }
        }
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !needle.isEmpty {
            result = result.filter { record in
                [record.title, record.category.rawValue, record.tagsText, record.context, record.actionTaken,
                 record.outcome, record.businessImpact, record.metrics, record.stakeholders,
                 record.humanValueAnalysis, record.professionalIntelligence]
                    .joined(separator: " ").lowercased().contains(needle)
            }
        }
        switch sort {
        case .newest: result.sort { $0.date > $1.date }
        case .oldest: result.sort { $0.date < $1.date }
        case .modified: result.sort { $0.modifiedAt > $1.modifiedAt }
        case .strongest: result.sort { ($0.claimStrength, $0.evidence.count, $0.date) > ($1.claimStrength, $1.evidence.count, $1.date) }
        }
        return result
    }

    private func prepareStorage() {
        do {
            try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: evidenceRootURL, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: backupsURL, withIntermediateDirectories: true)
        } catch { lastError = "Could not prepare accomplishment storage: \(error.localizedDescription)" }
    }

    private func evidenceDirectory(for id: UUID) -> URL { evidenceRootURL.appendingPathComponent(id.uuidString, isDirectory: true) }

    private func load() {
        guard fileManager.fileExists(atPath: recordsURL.path) else { return }
        do {
            let data = try Data(contentsOf: recordsURL)
            let decoder = JSONDecoder.incidentDecoder
            if let db = try? decoder.decode(AccomplishmentDatabase.self, from: data) {
                accomplishments = db.accomplishments
            } else {
                accomplishments = try decoder.decode([AccomplishmentRecord].self, from: data)
            }
        } catch { lastError = "Could not load accomplishments: \(error.localizedDescription)" }
    }

    private func persist() {
        do {
            createBackupIfPossible()
            let data = try JSONEncoder.incidentEncoder.encode(AccomplishmentDatabase(schemaVersion: 1, accomplishments: accomplishments))
            try data.write(to: recordsURL, options: .atomic)
            pruneBackups()
        } catch { lastError = "Could not save accomplishments: \(error.localizedDescription)" }
    }

    private func createBackupIfPossible() {
        guard fileManager.fileExists(atPath: recordsURL.path) else { return }
        let f = DateFormatter(); f.dateFormat = "yyyyMMdd-HHmmss-SSS"
        try? fileManager.copyItem(at: recordsURL, to: backupsURL.appendingPathComponent("accomplishments-\(f.string(from: Date())).json"))
    }

    private func pruneBackups(keeping limit: Int = 25) {
        guard let files = try? fileManager.contentsOfDirectory(at: backupsURL, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else { return }
        let sorted = files.sorted { lhs, rhs in
            let l = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let r = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return l > r
        }
        for old in sorted.dropFirst(limit) { try? fileManager.removeItem(at: old) }
    }

    private static func sha256(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
}
