import AppKit
import Foundation

enum WorkRecordStorage {
    static let customRootKey = "EntropyShieldWorkRecordRootPath"
    static let schemaVersion = 1

    static var defaultRootURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("EntropyShield/IncidentTracker", isDirectory: true)
    }

    static var rootURL: URL {
        if let path = UserDefaults.standard.string(forKey: customRootKey), !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
        }
        return defaultRootURL
    }

    static var incidentsURL: URL { rootURL.appendingPathComponent("incidents.json") }
    static var incidentEvidenceURL: URL { rootURL.appendingPathComponent("Evidence", isDirectory: true) }
    static var incidentBackupsURL: URL { rootURL.appendingPathComponent("Backups", isDirectory: true) }
    static var accomplishmentsRootURL: URL { rootURL.appendingPathComponent("Accomplishments", isDirectory: true) }
    static var accomplishmentsURL: URL { accomplishmentsRootURL.appendingPathComponent("accomplishments.json") }
    static var accomplishmentEvidenceURL: URL { accomplishmentsRootURL.appendingPathComponent("Evidence", isDirectory: true) }
    static var accomplishmentBackupsURL: URL { accomplishmentsRootURL.appendingPathComponent("Backups", isDirectory: true) }
    static var evidenceInboxURL: URL { rootURL.appendingPathComponent("Evidence Inbox", isDirectory: true) }
    static var workGraphRootURL: URL { rootURL.appendingPathComponent("WorkGraph", isDirectory: true) }
    static var workGraphURL: URL { workGraphRootURL.appendingPathComponent("work-graph.json") }
    static var workGraphBackupsURL: URL { workGraphRootURL.appendingPathComponent("Backups", isDirectory: true) }
    static var preventionLedgerRootURL: URL { rootURL.appendingPathComponent("PreventionLedger", isDirectory: true) }
    static var preventionLedgerURL: URL { preventionLedgerRootURL.appendingPathComponent("prevention-ledger.json") }
    static var preventionLedgerBackupsURL: URL { preventionLedgerRootURL.appendingPathComponent("Backups", isDirectory: true) }
    static var operationalBurdenRootURL: URL { rootURL.appendingPathComponent("OperationalBurden", isDirectory: true) }
    static var operationalBurdenURL: URL { operationalBurdenRootURL.appendingPathComponent("operational-burden.json") }
    static var operationalBurdenBackupsURL: URL { operationalBurdenRootURL.appendingPathComponent("Backups", isDirectory: true) }
    static var responsibilityDriftRootURL: URL { rootURL.appendingPathComponent("ResponsibilityDrift", isDirectory: true) }
    static var responsibilityDriftURL: URL { responsibilityDriftRootURL.appendingPathComponent("responsibility-drift.json") }
    static var responsibilityDriftBackupsURL: URL { responsibilityDriftRootURL.appendingPathComponent("Backups", isDirectory: true) }

    static func prepareRoot(_ root: URL = rootURL) throws {
        let fm = FileManager.default
        guard !isInsideGitWorkingTree(root) else {
            throw NSError(
                domain: "EntropyShieldStorage",
                code: 10,
                userInfo: [
                    NSLocalizedDescriptionKey: "For privacy, the Work Record database cannot be stored inside a Git working tree. Choose a separate local folder such as Application Support."
                ]
            )
        }
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        try fm.createDirectory(at: root.appendingPathComponent("Evidence", isDirectory: true), withIntermediateDirectories: true)
        try fm.createDirectory(at: root.appendingPathComponent("Backups", isDirectory: true), withIntermediateDirectories: true)
        let accomplishments = root.appendingPathComponent("Accomplishments", isDirectory: true)
        try fm.createDirectory(at: accomplishments, withIntermediateDirectories: true)
        try fm.createDirectory(at: accomplishments.appendingPathComponent("Evidence", isDirectory: true), withIntermediateDirectories: true)
        try fm.createDirectory(at: accomplishments.appendingPathComponent("Backups", isDirectory: true), withIntermediateDirectories: true)
        try fm.createDirectory(at: root.appendingPathComponent("Evidence Inbox", isDirectory: true), withIntermediateDirectories: true)
        try fm.createDirectory(at: root.appendingPathComponent("Evidence Inbox/Processed", isDirectory: true), withIntermediateDirectories: true)
        let workGraph = root.appendingPathComponent("WorkGraph", isDirectory: true)
        try fm.createDirectory(at: workGraph, withIntermediateDirectories: true)
        try fm.createDirectory(at: workGraph.appendingPathComponent("Backups", isDirectory: true), withIntermediateDirectories: true)
        let prevention = root.appendingPathComponent("PreventionLedger", isDirectory: true)
        try fm.createDirectory(at: prevention, withIntermediateDirectories: true)
        try fm.createDirectory(at: prevention.appendingPathComponent("Backups", isDirectory: true), withIntermediateDirectories: true)
        let operationalBurden = root.appendingPathComponent("OperationalBurden", isDirectory: true)
        try fm.createDirectory(at: operationalBurden, withIntermediateDirectories: true)
        try fm.createDirectory(at: operationalBurden.appendingPathComponent("Backups", isDirectory: true), withIntermediateDirectories: true)
        let responsibilityDrift = root.appendingPathComponent("ResponsibilityDrift", isDirectory: true)
        try fm.createDirectory(at: responsibilityDrift, withIntermediateDirectories: true)
        try fm.createDirectory(at: responsibilityDrift.appendingPathComponent("Backups", isDirectory: true), withIntermediateDirectories: true)
    }

    struct ValidationResult {
        let isValid: Bool
        let incidentCount: Int
        let accomplishmentCount: Int
        let evidenceFileCount: Int
        let totalBytes: Int64
        let message: String
    }

    static func validate(root: URL) -> ValidationResult {
        let fm = FileManager.default
        var incidentCount = 0
        var accomplishmentCount = 0
        var valid = true
        var notes: [String] = []

        let incidents = root.appendingPathComponent("incidents.json")
        if fm.fileExists(atPath: incidents.path) {
            do {
                let data = try Data(contentsOf: incidents)
                let decoder = JSONDecoder.incidentDecoder
                if let db = try? decoder.decode(IncidentDatabase.self, from: data) { incidentCount = db.incidents.count }
                else { incidentCount = try decoder.decode([IncidentRecord].self, from: data).count }
            } catch { valid = false; notes.append("incidents.json could not be decoded") }
        } else { notes.append("no incident database found") }

        let accomplishments = root.appendingPathComponent("Accomplishments/accomplishments.json")
        if fm.fileExists(atPath: accomplishments.path) {
            do {
                let data = try Data(contentsOf: accomplishments)
                let decoder = JSONDecoder.incidentDecoder
                if let db = try? decoder.decode(AccomplishmentDatabase.self, from: data) { accomplishmentCount = db.accomplishments.count }
                else { accomplishmentCount = try decoder.decode([AccomplishmentRecord].self, from: data).count }
            } catch { valid = false; notes.append("accomplishments.json could not be decoded") }
        } else { notes.append("no accomplishment database found") }

        let workGraph = root.appendingPathComponent("WorkGraph/work-graph.json")
        if fm.fileExists(atPath: workGraph.path) {
            do {
                let data = try Data(contentsOf: workGraph)
                _ = try JSONDecoder.incidentDecoder.decode(WorkGraphDatabase.self, from: data)
            } catch {
                valid = false
                notes.append("work-graph.json could not be decoded")
            }
        }

        let preventionLedger = root.appendingPathComponent("PreventionLedger/prevention-ledger.json")
        if fm.fileExists(atPath: preventionLedger.path) {
            do {
                let data = try Data(contentsOf: preventionLedger)
                _ = try JSONDecoder.incidentDecoder.decode(PreventionLedgerDatabase.self, from: data)
            } catch {
                valid = false
                notes.append("prevention-ledger.json could not be decoded")
            }
        }

        let operationalBurden = root.appendingPathComponent("OperationalBurden/operational-burden.json")
        if fm.fileExists(atPath: operationalBurden.path) {
            do {
                let data = try Data(contentsOf: operationalBurden)
                _ = try JSONDecoder.incidentDecoder.decode(OperationalBurdenDatabase.self, from: data)
            } catch {
                valid = false
                notes.append("operational-burden.json could not be decoded")
            }
        }

        let responsibilityDrift = root.appendingPathComponent("ResponsibilityDrift/responsibility-drift.json")
        if fm.fileExists(atPath: responsibilityDrift.path) {
            do {
                let data = try Data(contentsOf: responsibilityDrift)
                _ = try JSONDecoder.incidentDecoder.decode(ResponsibilityDriftDatabase.self, from: data)
            } catch {
                valid = false
                notes.append("responsibility-drift.json could not be decoded")
            }
        }

        let stats = directoryStats(root)
        if !fm.fileExists(atPath: root.path) { valid = false; notes.append("folder does not exist") }
        let message = valid ? "Valid Work Record repository. \(incidentCount) incidents, \(accomplishmentCount) accomplishments, \(stats.files) evidence/data files." : "Repository validation failed: \(notes.joined(separator: ", "))."
        return ValidationResult(isValid: valid, incidentCount: incidentCount, accomplishmentCount: accomplishmentCount, evidenceFileCount: stats.files, totalBytes: stats.bytes, message: message)
    }

    static func setRoot(_ root: URL?) {
        if let root { UserDefaults.standard.set(root.standardizedFileURL.path, forKey: customRootKey) }
        else { UserDefaults.standard.removeObject(forKey: customRootKey) }
    }

    static func moveRepository(to destination: URL) throws {
        let fm = FileManager.default
        let source = rootURL.standardizedFileURL
        let dest = destination.standardizedFileURL
        guard source != dest else { return }
        if dest.path.hasPrefix(source.path + "/") {
            throw NSError(domain: "EntropyShieldStorage", code: 4, userInfo: [NSLocalizedDescriptionKey: "Choose a destination outside the current Work Record repository."])
        }
        try prepareRoot(source)
        if fm.fileExists(atPath: dest.path), !(try fm.contentsOfDirectory(atPath: dest.path)).isEmpty {
            throw NSError(domain: "EntropyShieldStorage", code: 2, userInfo: [NSLocalizedDescriptionKey: "The destination folder is not empty. Choose an empty folder or use Link Existing Database instead."])
        }
        if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
        try fm.copyItem(at: source, to: dest)
        let check = validate(root: dest)
        guard check.isValid else {
            try? fm.removeItem(at: dest)
            throw NSError(domain: "EntropyShieldStorage", code: 3, userInfo: [NSLocalizedDescriptionKey: "The copied repository did not pass validation. The active database was not changed."])
        }
        setRoot(dest)
    }

    static func revealCurrentRoot() { NSWorkspace.shared.activateFileViewerSelecting([rootURL]) }

    static func isInsideGitWorkingTree(_ url: URL) -> Bool {
        let fm = FileManager.default
        var current = url.standardizedFileURL

        while true {
            if fm.fileExists(atPath: current.appendingPathComponent(".git").path) {
                return true
            }

            let parent = current.deletingLastPathComponent()
            if parent.path == current.path { break }
            current = parent
        }

        return false
    }

    private static func directoryStats(_ root: URL) -> (files: Int, bytes: Int64) {
        let fm = FileManager.default
        guard let e = fm.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey], options: [.skipsHiddenFiles]) else { return (0, 0) }
        var files = 0; var bytes: Int64 = 0
        for case let u as URL in e {
            guard let v = try? u.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]), v.isRegularFile == true else { continue }
            files += 1; bytes += Int64(v.fileSize ?? 0)
        }
        return (files, bytes)
    }
}
