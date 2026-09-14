import Foundation
import SwiftData
import AppKit

struct IngestedDraft {
    let title: String
    let body: String
    let sourceURL: URL?
}

enum IngestionService {
    private static let inboxName = "Evidence Inbox"
    /// Keeps activation-time ingestion responsive on 16 GB unified-memory Macs.
    static let maxFilesPerScan = 24

    static func inboxDirectory() throws -> URL {
        let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let folder = support.appendingPathComponent("WorkEvidence", isDirectory: true).appendingPathComponent(inboxName, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    @MainActor
    static func revealInbox() {
        if let url = try? inboxDirectory() { NSWorkspace.shared.activateFileViewerSelecting([url]) }
    }

    @MainActor
    static func scanInbox(modelContext: ModelContext) throws -> Int {
        let inbox = try inboxDirectory()
        let processed = inbox.appendingPathComponent("Processed", isDirectory: true)
        try FileManager.default.createDirectory(at: processed, withIntermediateDirectories: true)
        let files = try FileManager.default.contentsOfDirectory(at: inbox, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
            .filter { (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true }
            .prefix(maxFilesPerScan)

        var count = 0
        for file in files {
            let entry = Accomplishment(date: .now, title: titleFromFilename(file), category: .other)
            let ext = file.pathExtension.lowercased()
            if ["txt", "md", "log"].contains(ext), let text = try? String(contentsOf: file, encoding: .utf8) {
                entry.context = String(text.prefix(8000))
                entry.evidenceNotes = "Automatically ingested from Evidence Inbox: \(file.lastPathComponent)"
            } else if ext == "json", let data = try? Data(contentsOf: file), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                entry.title = (json["title"] as? String) ?? entry.title
                entry.context = (json["context"] as? String) ?? (json["note"] as? String) ?? ""
                entry.actionTaken = (json["action"] as? String) ?? ""
                entry.outcome = (json["outcome"] as? String) ?? ""
                entry.businessImpact = (json["impact"] as? String) ?? ""
                entry.metrics = (json["metrics"] as? String) ?? ""
                entry.stakeholders = (json["stakeholders"] as? String) ?? ""
                entry.tagsText = (json["tags"] as? String) ?? ""
                entry.evidenceNotes = "Automatically ingested structured record: \(file.lastPathComponent)"
            } else {
                entry.context = "Automatically captured evidence. Review this draft and describe the accomplishment it supports."
                let imported = try AttachmentStore.importFiles([file], for: entry.id)
                for item in imported {
                    let attachment = EvidenceAttachment(originalFilename: item.originalFilename, relativePath: item.relativePath, byteCount: item.byteCount)
                    modelContext.insert(attachment)
                    entry.attachments.append(attachment)
                }
            }
            modelContext.insert(entry)
            let destination = uniqueDestination(for: file, in: processed)
            try? FileManager.default.moveItem(at: file, to: destination)
            count += 1
        }
        try modelContext.save()
        return count
    }

    @MainActor
    static func ingestCaptureURL(_ url: URL, modelContext: ModelContext) -> Accomplishment? {
        guard url.scheme?.lowercased() == "accomplishmenttracker" else { return nil }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name.lowercased(), $0.value ?? "") })
        let title = items["title"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let note = items["note"] ?? items["context"] ?? ""
        guard !title.isEmpty || !note.isEmpty else { return nil }
        let entry = Accomplishment(date: .now, title: title.isEmpty ? "Captured accomplishment" : title, category: .other, context: note)
        entry.evidenceNotes = "Captured through local URL ingestion endpoint."
        if let source = items["source"], !source.isEmpty { entry.tagsText = "source:\(source)" }
        modelContext.insert(entry)
        try? modelContext.save()
        return entry
    }

    private static func titleFromFilename(_ url: URL) -> String {
        url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
    }

    private static func uniqueDestination(for source: URL, in folder: URL) -> URL {
        var target = folder.appendingPathComponent(source.lastPathComponent)
        if FileManager.default.fileExists(atPath: target.path) {
            target = folder.appendingPathComponent("\(UUID().uuidString)-\(source.lastPathComponent)")
        }
        return target
    }
}
