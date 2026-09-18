import AppKit
import Foundation

@MainActor
enum AccomplishmentIntakeService {
    static let maxFilesPerScan = 24
    static func inboxDirectory() throws -> URL {
        let url = WorkRecordStorage.evidenceInboxURL
        try FileManager.default.createDirectory(at:url,withIntermediateDirectories:true)
        return url
    }
    static func revealInbox() { if let url = try? inboxDirectory() { NSWorkspace.shared.activateFileViewerSelecting([url]) } }
    static func scanInbox(store: AccomplishmentStore) throws -> Int {
        let inbox = try inboxDirectory(); let processed = inbox.appendingPathComponent("Processed",isDirectory:true)
        try FileManager.default.createDirectory(at:processed,withIntermediateDirectories:true)
        let files = try FileManager.default.contentsOfDirectory(at:inbox,includingPropertiesForKeys:[.isRegularFileKey],options:[.skipsHiddenFiles]).filter { (try? $0.resourceValues(forKeys:[.isRegularFileKey]).isRegularFile) == true }.prefix(maxFilesPerScan)
        var count=0
        for file in files {
            var r = store.createAccomplishment(); r.category = .other; r.isDraft = true
            let ext=file.pathExtension.lowercased()
            if ["txt","md","log"].contains(ext), let text=try? String(contentsOf:file,encoding:.utf8) {
                r.title = file.deletingPathExtension().lastPathComponent.replacingOccurrences(of:"_",with:" "); r.context = String(text.prefix(8000)); r.evidenceNotes = "Imported from Evidence Inbox: \(file.lastPathComponent)"
            } else if ext == "json", let data=try? Data(contentsOf:file), let json=try? JSONSerialization.jsonObject(with:data) as? [String:Any] {
                r.title = (json["title"] as? String) ?? file.deletingPathExtension().lastPathComponent
                r.context = (json["context"] as? String) ?? (json["note"] as? String) ?? ""; r.actionTaken=(json["action"] as? String) ?? ""; r.outcome=(json["outcome"] as? String) ?? ""; r.businessImpact=(json["impact"] as? String) ?? ""; r.metrics=(json["metrics"] as? String) ?? ""; r.stakeholders=(json["stakeholders"] as? String) ?? ""
                if let tags=json["tags"] as? String { r.tagsText=tags }; r.evidenceNotes = "Imported structured record: \(file.lastPathComponent)"
            } else {
                r.title = file.deletingPathExtension().lastPathComponent; r.context = "Imported evidence. Review this draft and describe the accomplishment it supports."; r.tags = ["evidence-inbox","needs-review"]
                store.save(r); try store.importEvidence(urls:[file],into:r.id); r = store.accomplishment(id:r.id) ?? r
            }
            store.save(r)
            var dest=processed.appendingPathComponent(file.lastPathComponent); if FileManager.default.fileExists(atPath:dest.path){dest=processed.appendingPathComponent(UUID().uuidString+"-"+file.lastPathComponent)}; try? FileManager.default.moveItem(at:file,to:dest); count += 1
        }
        return count
    }
    static func ingest(url: URL, store: AccomplishmentStore) -> AccomplishmentRecord? {
        guard url.scheme?.lowercased() == "entropyshield" || url.scheme?.lowercased() == "accomplishmenttracker" else { return nil }
        let c = URLComponents(url: url, resolvingAgainstBaseURL: false); let items=Dictionary(uniqueKeysWithValues:(c?.queryItems ?? []).map{($0.name.lowercased(),$0.value ?? "")}); let title=items["title"]?.trimmingCharacters(in:.whitespacesAndNewlines) ?? ""; let note=items["note"] ?? items["context"] ?? ""; guard !title.isEmpty || !note.isEmpty else{return nil}
        var r=store.createAccomplishment(); r.title = title.isEmpty ? "Captured accomplishment" : title; r.context = note; r.category = .other; r.tags = ["source:external-url","needs-review"]; r.evidenceNotes = "Captured through the local URL ingestion endpoint. Review before relying on it as evidence."; store.save(r); return r
    }
}
