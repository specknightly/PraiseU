import Combine
import Foundation

@MainActor
final class OperationalBurdenStore: ObservableObject {
    @Published private(set) var records: [OperationalBurdenRecord] = []
    @Published var lastError: String?

    private let fileManager = FileManager.default
    private var recordsURL: URL { WorkRecordStorage.operationalBurdenURL }
    private var backupsURL: URL { WorkRecordStorage.operationalBurdenBackupsURL }

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

    var measuredBurdenMinutes: Int {
        records.filter { $0.evidenceBasis == .measured }.reduce(0) { $0 + $1.totalBurdenMinutes }
    }

    var estimatedBurdenMinutes: Int {
        records.filter { $0.evidenceBasis == .estimated }.reduce(0) { $0 + $1.totalBurdenMinutes }
    }

    var measuredAfterHoursMinutes: Int {
        records.filter { $0.evidenceBasis == .measured }.reduce(0) { $0 + $1.safeAfterHoursMinutes }
    }

    var estimatedAfterHoursMinutes: Int {
        records.filter { $0.evidenceBasis == .estimated }.reduce(0) { $0 + $1.safeAfterHoursMinutes }
    }

    var totalInterruptions: Int {
        records.reduce(0) { $0 + $1.safeInterruptionCount }
    }

    var totalContextSwitches: Int {
        records.reduce(0) { $0 + $1.safeContextSwitchCount }
    }

    var averageCognitiveLoad: Double {
        guard !records.isEmpty else { return 0 }
        return Double(records.reduce(0) { $0 + $1.cognitiveLoad }) / Double(records.count)
    }

    var averageCoordinationLoad: Double {
        guard !records.isEmpty else { return 0 }
        return Double(records.reduce(0) { $0 + $1.coordinationLoad }) / Double(records.count)
    }

    var kindSummaries: [OperationalBurdenKindSummary] {
        OperationalBurdenKind.allCases.compactMap { kind in
            let matching = records.filter { $0.kind == kind }
            guard !matching.isEmpty else { return nil }
            return OperationalBurdenKindSummary(
                kind: kind,
                measuredMinutes: matching.filter { $0.evidenceBasis == .measured }.reduce(0) { $0 + $1.totalBurdenMinutes },
                estimatedMinutes: matching.filter { $0.evidenceBasis == .estimated }.reduce(0) { $0 + $1.totalBurdenMinutes },
                recordCount: matching.count
            )
        }
        .sorted {
            if $0.totalMinutes != $1.totalMinutes { return $0.totalMinutes > $1.totalMinutes }
            return $0.kind.rawValue < $1.kind.rawValue
        }
    }

    func record(id: UUID) -> OperationalBurdenRecord? {
        records.first { $0.id == id }
    }

    func records(linkedTo node: WorkGraphNodeRef) -> [OperationalBurdenRecord] {
        records.filter { $0.sourceRecord == node || $0.linkedNodes.contains(node) }
            .sorted { $0.date > $1.date }
    }

    @discardableResult
    func create(sourceRecord: WorkGraphNodeRef? = nil) -> OperationalBurdenRecord {
        var record = OperationalBurdenRecord()
        record.sourceRecord = sourceRecord
        record.modifiedAt = Date()
        records.insert(record, at: 0)
        persist()
        return record
    }

    func save(_ record: OperationalBurdenRecord) {
        var updated = record
        updated.title = updated.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if updated.title.isEmpty { updated.title = "Untitled Burden" }

        updated.durationMinutes = nonNegative(updated.durationMinutes)
        updated.recoveryMinutes = nonNegative(updated.recoveryMinutes)
        updated.afterHoursMinutes = nonNegative(updated.afterHoursMinutes)
        updated.interruptionCount = nonNegative(updated.interruptionCount)
        updated.contextSwitchCount = nonNegative(updated.contextSwitchCount)
        updated.cognitiveLoad = min(5, max(1, updated.cognitiveLoad))
        updated.coordinationLoad = min(5, max(0, updated.coordinationLoad))

        if let active = updated.durationMinutes, let afterHours = updated.afterHoursMinutes, afterHours > active {
            updated.afterHoursMinutes = active
        }

        updated.linkedNodes = Array(Set(updated.linkedNodes)).sorted { $0.stableKey < $1.stableKey }
        updated.modifiedAt = Date()

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

    private func prepareStorage() {
        do {
            try WorkRecordStorage.prepareRoot()
            try fileManager.createDirectory(at: backupsURL, withIntermediateDirectories: true)
        } catch {
            lastError = "Could not prepare Operational Burden storage: \(error.localizedDescription)"
        }
    }

    private func load() {
        guard fileManager.fileExists(atPath: recordsURL.path) else { return }
        do {
            let data = try Data(contentsOf: recordsURL)
            let database = try JSONDecoder.incidentDecoder.decode(OperationalBurdenDatabase.self, from: data)
            records = database.records
            sortRecords()
        } catch {
            lastError = "Could not load Operational Burden data: \(error.localizedDescription)"
        }
    }

    private func persist() {
        do {
            createBackupIfPossible()
            let database = OperationalBurdenDatabase(schemaVersion: 1, records: records)
            let data = try JSONEncoder.incidentEncoder.encode(database)
            try data.write(to: recordsURL, options: .atomic)
            pruneBackups()
        } catch {
            lastError = "Could not save Operational Burden data: \(error.localizedDescription)"
        }
    }

    private func createBackupIfPossible() {
        guard fileManager.fileExists(atPath: recordsURL.path) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let backup = backupsURL.appendingPathComponent("operational-burden-\(formatter.string(from: Date())).json")
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

    private func sortRecords() {
        records.sort {
            if $0.date != $1.date { return $0.date > $1.date }
            return $0.modifiedAt > $1.modifiedAt
        }
    }
}
