import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
enum AccomplishmentExportService {
    static func export(_ record: AccomplishmentRecord, store: AccomplishmentStore) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.html]
        panel.nameFieldStringValue = safeFilename(record.title.isEmpty ? "Accomplishment" : record.title) + ".html"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try html(for: record, store: store).write(to: url, atomically: true, encoding: .utf8) }
        catch { store.lastError = "Could not export accomplishment: \(error.localizedDescription)" }
    }

    static func exportReviewPacket(_ records: [AccomplishmentRecord], store: AccomplishmentStore) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.html]
        panel.nameFieldStringValue = "Accomplishment-Review-\(Date().formatted(.dateTime.year().month().day())).html"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let cards = records.map { card(for: $0, store: store) }.joined(separator: "\n")
            let page = document(title: "Accomplishment Review", subtitle: "Evidence-backed record of completed work", body: cards.isEmpty ? "<section class='card'><h2>No matching accomplishments</h2></section>" : cards)
            try page.write(to: url, atomically: true, encoding: .utf8)
        } catch { store.lastError = "Could not export accomplishment review: \(error.localizedDescription)" }
    }

    private static func html(for r: AccomplishmentRecord, store: AccomplishmentStore) -> String {
        let evidence = r.evidence.map { item in
            let verified = store.verifyEvidence(item, accomplishmentID: r.id) ? "Verified" : "Missing or changed"
            return "<li><b>\(escape(item.originalName))</b> · \(verified) · SHA-256 \(escape(item.sha256))\(item.note.isEmpty ? "" : "<br>\(escape(item.note))")</li>"
        }.joined()
        let evidencePreviews = r.evidence.prefix(10).compactMap { evidencePreview($0, record: r, store: store) }.joined(separator: "\n")
        let body = """
        <section class='card hero'><div class='eyebrow'>\(escape(r.category.rawValue)) · \(escape(r.date.formatted(date: .long, time: .omitted)))</div><h1>\(escape(r.title))</h1><div class='chips'><span>\(r.isDraft ? "Draft" : "Completed")</span><span>\(escape(r.responsibilityScope.rawValue))</span><span>\(escape(r.workLevel.rawValue))</span></div></section>
        \(section("Context / Challenge", r.context))
        \(section("Action Taken", r.actionTaken))
        \(section("Outcome", r.outcome))
        \(section("Business / Operational Impact", r.businessImpact))
        \(section("Metrics", r.metrics))
        \(section("Stakeholders", r.stakeholders))
        \(section("Why Human Judgment Mattered", r.humanValueAnalysis))
        \(section("Scope Inference", r.scopeInference))
        \(section("Professional Intelligence", r.professionalIntelligence))
        \(section("Evidence Analysis", r.evidenceAnalysis))
        <section class='card'><h2>Evidence</h2><ul>\(evidence.isEmpty ? "<li>No files attached</li>" : evidence)</ul>\(evidencePreviews.isEmpty ? "" : "<div class='evidence-grid'>\(evidencePreviews)</div>")</section>
        """
        return document(title: r.title, subtitle: "Entropy Shield Accomplishment Tracker", body: body)
    }

    private static func card(for r: AccomplishmentRecord, store: AccomplishmentStore) -> String {
        let previews = r.evidence.prefix(6).compactMap { evidencePreview($0, record: r, store: store) }.joined(separator: "\n")
        return """
        <section class='card'><div class='eyebrow'>\(escape(r.date.formatted(date: .abbreviated, time: .omitted))) · \(escape(r.category.rawValue))</div><h2>\(escape(r.title))</h2>
        <p><b>Action:</b> \(escape(r.actionTaken))</p><p><b>Outcome:</b> \(escape(r.outcome))</p><p><b>Impact:</b> \(escape(r.businessImpact))</p>
        <div class='chips'><span>Evidence: \(r.evidence.count)</span><span>Claim strength: \(r.claimStrength)</span><span>\(escape(r.workLevel.rawValue))</span></div>
        \(previews.isEmpty ? "" : "<div class='evidence-grid'>\(previews)</div>")
        </section>
        """
    }

    private static func evidencePreview(_ item: AccomplishmentEvidenceItem, record: AccomplishmentRecord, store: AccomplishmentStore) -> String? {
        let url = store.evidenceURL(for: item, accomplishmentID: record.id)
        guard item.byteCount <= 20_000_000, let data = try? Data(contentsOf: url) else { return nil }
        let ext = url.pathExtension.lowercased()
        let encoded = data.base64EncodedString()
        if ["png", "jpg", "jpeg", "gif", "webp"].contains(ext) {
            let mime = ext == "jpg" || ext == "jpeg" ? "image/jpeg" : "image/\(ext)"
            return "<figure><img src='data:\(mime);base64,\(encoded)' alt='\(escape(item.originalName))'><figcaption>\(escape(item.originalName))</figcaption></figure>"
        }
        if ext == "pdf" {
            return "<figure class='pdf'><object data='data:application/pdf;base64,\(encoded)' type='application/pdf'><p>PDF evidence: \(escape(item.originalName))</p></object><figcaption>\(escape(item.originalName))</figcaption></figure>"
        }
        return nil
    }

    private static func section(_ title: String, _ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return "<section class='card'><h2>\(escape(title))</h2><p>\(escape(trimmed).replacingOccurrences(of: "\n", with: "<br>"))</p></section>"
    }

    private static func document(title: String, subtitle: String, body: String) -> String {
        """
        <!doctype html><html lang='en'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>\(escape(title))</title>
        <style>body{margin:0;background:#07111d;color:#eef5ff;font:15px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}main{max-width:980px;margin:32px auto;padding:0 24px 60px}.mast{padding:28px 4px}.mast h1{margin:0;font-size:36px}.mast p{color:#aab8c8}.card{background:#0b2033;border:1px solid rgba(255,255,255,.09);border-radius:16px;padding:22px;margin:14px 0}.hero{border-left:4px solid #ffba2e}.eyebrow{text-transform:uppercase;letter-spacing:.08em;font-size:11px;color:#9cb0c5}.card h1,.card h2{margin:.2em 0 .5em}.chips{display:flex;gap:8px;flex-wrap:wrap}.chips span{background:#12304a;border-radius:999px;padding:5px 10px;font-size:12px}b{color:#ffcc67}ul{padding-left:20px}.evidence-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:12px;margin-top:16px}.evidence-grid figure{margin:0;background:#071725;border-radius:10px;padding:8px}.evidence-grid img{width:100%;max-height:360px;object-fit:contain;border-radius:7px}.evidence-grid object{width:100%;height:360px;border:0;background:white}.evidence-grid figcaption{font-size:11px;color:#9cb0c5;margin-top:6px;word-break:break-all}@media print{body{background:white;color:#111}.card{background:white;border:1px solid #ddd}.mast p,.eyebrow{color:#555}.chips span{background:#eee}}</style></head>
        <body><main><header class='mast'><h1>\(escape(title))</h1><p>\(escape(subtitle))</p></header>\(body)</main></body></html>
        """
    }

    private static func escape(_ s: String) -> String { s.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;").replacingOccurrences(of: "'", with: "&#39;") }
    private static func safeFilename(_ s: String) -> String { s.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-") }
}
