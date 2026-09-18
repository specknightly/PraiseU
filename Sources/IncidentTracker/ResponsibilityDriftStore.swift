import Combine
import Foundation

@MainActor
final class ResponsibilityDriftStore: ObservableObject {
    @Published private(set) var baselines: [RoleBaselineSnapshot] = []
    @Published var lastError: String?

    private let fileManager = FileManager.default
    private var recordsURL: URL { WorkRecordStorage.responsibilityDriftURL }
    private var backupsURL: URL { WorkRecordStorage.responsibilityDriftBackupsURL }

    init() {
        prepareStorage()
        load()
    }

    func reloadFromStorage() {
        baselines = []
        prepareStorage()
        load()
    }

    @discardableResult
    func createBaseline(
        roleTitle: String,
        roleDefinition: String,
        expectedAdjacentPercent: Double,
        effectiveDate: Date = Date(),
        notes: String = ""
    ) -> RoleBaselineSnapshot {
        let snapshot = RoleBaselineSnapshot(
            effectiveDate: effectiveDate,
            roleTitle: roleTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            roleDefinition: roleDefinition.trimmingCharacters(in: .whitespacesAndNewlines),
            expectedAdjacentPercent: min(100, max(0, expectedAdjacentPercent)),
            notes: notes
        )
        baselines.append(snapshot)
        sortBaselines()
        persist()
        return snapshot
    }

    func save(_ baseline: RoleBaselineSnapshot) {
        var updated = baseline
        updated.roleTitle = updated.roleTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.roleDefinition = updated.roleDefinition.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.expectedAdjacentPercent = min(100, max(0, updated.expectedAdjacentPercent))
        updated.modifiedAt = Date()

        if let index = baselines.firstIndex(where: { $0.id == updated.id }) {
            baselines[index] = updated
        } else {
            baselines.append(updated)
        }
        sortBaselines()
        persist()
    }

    func delete(_ id: UUID) {
        baselines.removeAll { $0.id == id }
        persist()
    }

    func baseline(effectiveOn date: Date) -> RoleBaselineSnapshot? {
        baselines
            .filter { $0.effectiveDate <= date }
            .max { $0.effectiveDate < $1.effectiveDate }
            ?? baselines.min { $0.effectiveDate < $1.effectiveDate }
    }

    var latestBaseline: RoleBaselineSnapshot? {
        baselines.max { $0.effectiveDate < $1.effectiveDate }
    }

    private func prepareStorage() {
        do {
            try WorkRecordStorage.prepareRoot()
            try fileManager.createDirectory(at: backupsURL, withIntermediateDirectories: true)
        } catch {
            lastError = "Could not prepare Responsibility Drift storage: \(error.localizedDescription)"
        }
    }

    private func load() {
        guard fileManager.fileExists(atPath: recordsURL.path) else { return }
        do {
            let data = try Data(contentsOf: recordsURL)
            let database = try JSONDecoder.incidentDecoder.decode(ResponsibilityDriftDatabase.self, from: data)
            baselines = database.baselines
            sortBaselines()
        } catch {
            lastError = "Could not load Responsibility Drift baselines: \(error.localizedDescription)"
        }
    }

    private func persist() {
        do {
            createBackupIfPossible()
            let database = ResponsibilityDriftDatabase(schemaVersion: 1, baselines: baselines)
            let data = try JSONEncoder.incidentEncoder.encode(database)
            try data.write(to: recordsURL, options: .atomic)
            pruneBackups()
        } catch {
            lastError = "Could not save Responsibility Drift baselines: \(error.localizedDescription)"
        }
    }

    private func createBackupIfPossible() {
        guard fileManager.fileExists(atPath: recordsURL.path) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let backup = backupsURL.appendingPathComponent("responsibility-drift-\(formatter.string(from: Date())).json")
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

    private func sortBaselines() {
        baselines.sort {
            if $0.effectiveDate != $1.effectiveDate { return $0.effectiveDate > $1.effectiveDate }
            return $0.modifiedAt > $1.modifiedAt
        }
    }
}
