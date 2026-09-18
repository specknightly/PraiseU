import Combine
import Foundation

@MainActor
final class PreventionLedgerStore: ObservableObject {
    @Published private(set) var records: [PreventionInterventionRecord] = []
    @Published var lastError: String?

    private let fileManager = FileManager.default
    private var recordsURL: URL { WorkRecordStorage.preventionLedgerURL }
    private var backupsURL: URL { WorkRecordStorage.preventionLedgerBackupsURL }

    init() {
        prepareStorage()
        load()
    }

    func reloadFromStorage() {
        records = []
        prepareStorage()
        load()
    }

    var totalCount: Int { records.count }
    var measuredCount: Int { records.filter { $0.evidenceBasis == .measured }.count }
    var quantifiedCount: Int { records.filter(\.hasQuantification).count }
    var measuredHoursAvoided: Double {
        records.filter { $0.evidenceBasis == .measured }.compactMap { $0.hoursAvoided }.reduce(0, +)
    }
    var estimatedHoursAvoided: Double {
        records.filter { $0.evidenceBasis == .estimated }.compactMap { $0.hoursAvoided }.reduce(0, +)
    }
    var measuredRecurrencesAvoided: Int {
        records.filter { $0.evidenceBasis == .measured }.compactMap { $0.recurrenceCountAvoided }.reduce(0, +)
    }
    var estimatedRecurrencesAvoided: Int {
        records.filter { $0.evidenceBasis == .estimated }.compactMap { $0.recurrenceCountAvoided }.reduce(0, +)
    }

    func record(id: UUID) -> PreventionInterventionRecord? {
        records.first { $0.id == id }
    }

    func records(linkedTo node: WorkGraphNodeRef) -> [PreventionInterventionRecord] {
        records.filter { $0.sourceRecord == node || $0.linkedNodes.contains(node) }
            .sorted { $0.date > $1.date }
    }

    @discardableResult
    func create(sourceRecord: WorkGraphNodeRef? = nil) -> PreventionInterventionRecord {
        var record = PreventionInterventionRecord()
        record.sourceRecord = sourceRecord
        record.modifiedAt = Date()
        records.insert(record, at: 0)
        persist()
        return record
    }

    func save(_ record: PreventionInterventionRecord) {
        var updated = record
        updated.title = updated.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if updated.title.isEmpty { updated.title = "Untitled Prevention" }
        updated.recurrenceCountAvoided = nonNegative(updated.recurrenceCountAvoided)
        updated.hoursAvoided = nonNegative(updated.hoursAvoided)
        updated.peopleOrSystemsProtected = nonNegative(updated.peopleOrSystemsProtected)
        updated.modifiedAt = Date()

        if updated.evidenceBasis == .inferred {
            updated.recurrenceCountAvoided = nil
            updated.hoursAvoided = nil
            updated.peopleOrSystemsProtected = nil
        }

        if let index = records.firstIndex(where: { $0.id == updated.id }) {
            records[index] = updated
        } else {
            records.insert(updated, at: 0)
        }
        sortRecords()
        persist()
    }

    func delete(_ id: UUID) {
        records.removeAll { $0.id == id }
        persist()
    }

    private func nonNegative(_ value: Int?) -> Int? {
        guard let value else { return nil }
        return max(0, value)
    }

    private func nonNegative(_ value: Double?) -> Double? {
        guard let value else { return nil }
        return max(0, value)
    }

    private func prepareStorage() {
        do {
            try WorkRecordStorage.prepareRoot()
            try fileManager.createDirectory(at: backupsURL, withIntermediateDirectories: true)
        } catch {
            lastError = "Could not prepare Prevention Ledger storage: \(error.localizedDescription)"
        }
    }

    private func load() {
        guard fileManager.fileExists(atPath: recordsURL.path) else { return }
        do {
            let data = try Data(contentsOf: recordsURL)
            let database = try JSONDecoder.incidentDecoder.decode(PreventionLedgerDatabase.self, from: data)
            records = database.records
            sortRecords()
        } catch {
            lastError = "Could not load Prevention Ledger: \(error.localizedDescription)"
        }
    }

    private func persist() {
        do {
            createBackupIfPossible()
            let database = PreventionLedgerDatabase(schemaVersion: 1, records: records)
            let data = try JSONEncoder.incidentEncoder.encode(database)
            try data.write(to: recordsURL, options: .atomic)
            pruneBackups()
        } catch {
            lastError = "Could not save Prevention Ledger: \(error.localizedDescription)"
        }
    }

    private func createBackupIfPossible() {
        guard fileManager.fileExists(atPath: recordsURL.path) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let backup = backupsURL.appendingPathComponent("prevention-ledger-\(formatter.string(from: Date())).json")
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
        for old in sorted.dropFirst(limit) { try? fileManager.removeItem(at: old) }
    }

    private func sortRecords() {
        records.sort { $0.date > $1.date }
    }
}
