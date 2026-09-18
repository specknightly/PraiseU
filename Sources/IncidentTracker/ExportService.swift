import AppKit
import Foundation
import UniformTypeIdentifiers

enum ExportService {
    @MainActor
    static func exportIncident(_ incident: IncidentRecord, store: IncidentStore) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.html]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "Incident-\(safeFilename(incident.title))-\(dateStamp(incident.occurredAt)).html"
        panel.message = "Export a self-contained incident packet with embedded evidence."
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let html = try incidentHTML(incident, store: store)
            try html.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            store.lastError = "Could not export incident packet: \(error.localizedDescription)"
        }
    }

    @MainActor
    static func exportReviewPacket(_ incidents: [IncidentRecord], store: IncidentStore) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.html]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "Incident-Review-Packet-\(dateStamp(Date())).html"
        panel.message = "Export the current incident set as a self-contained review packet."
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let html = try reviewHTML(incidents, store: store)
            try html.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            store.lastError = "Could not export review packet: \(error.localizedDescription)"
        }
    }

    @MainActor
    private static func incidentHTML(_ incident: IncidentRecord, store: IncidentStore) throws -> String {
        let evidence = try evidenceHTML(incident, store: store)
        let aiBlock = incident.aiAnalysis.isEmpty ? "" : card("AI-assisted context", incident.aiAnalysis, code: "AI", muted: true)
        return documentShell(
            title: "Incident Packet: \(incident.title)",
            subtitle: "Document Today. Defend Tomorrow.",
            body: """
            \(hero(for: incident))
            <section class="grid two">
              \(card("Observed facts", incident.observedFacts, code: "01"))
              \(card("Context / interpretation", incident.contextInterpretation, code: "02"))
              \(card("Impact", incident.impact, code: "03"))
              \(card("Response taken", incident.response, code: "04"))
              \(card("Resolution / outcome", incident.resolution, code: "05"))
              \(card("Follow-up", incident.followUp, code: "06"))
            </section>
            <section class="grid two">
              \(card("Location / system", incident.locationOrSystem, code: "SYS"))
              \(card("People involved", incident.peopleInvolved, code: "PPL"))
              \(card("Witnesses", incident.witnesses, code: "WIT"))
              \(card("References", incident.referenceNumbers, code: "REF"))
            </section>
            \(aiBlock)
            <section class="section-title"><span>Evidence</span><small>Original copied files with recorded SHA-256 hashes</small></section>
            \(evidence)
            \(card("Notes", incident.notes, code: "NTE"))
            """
        )
    }

    @MainActor
    private static func reviewHTML(_ incidents: [IncidentRecord], store: IncidentStore) throws -> String {
        let sorted = incidents.sorted { $0.occurredAt > $1.occurredAt }
        let critical = sorted.filter { $0.severity == .critical }.count
        let open = sorted.filter { [.open, .monitoring].contains($0.status) }.count
        let resolved = sorted.filter { [.resolved, .closed].contains($0.status) }.count

        var body = """
        <section class="summary-grid">
          <div class="metric"><b>\(sorted.count)</b><span>Total incidents</span></div>
          <div class="metric"><b>\(open)</b><span>Open / monitoring</span></div>
          <div class="metric"><b>\(resolved)</b><span>Resolved / closed</span></div>
          <div class="metric"><b>\(critical)</b><span>Critical</span></div>
        </section>
        """

        for (index, incident) in sorted.enumerated() {
            let evidence = try evidenceHTML(incident, store: store)
            body += """
            <section class="record-break">
              <div class="eyebrow">INCIDENT \(String(format: "%03d", index + 1))</div>
              \(hero(for: incident))
              <section class="grid two">
                \(card("Observed facts", incident.observedFacts, code: "01"))
                \(card("Impact", incident.impact, code: "02"))
                \(card("Response taken", incident.response, code: "03"))
                \(card("Resolution / outcome", incident.resolution, code: "04"))
                \(card("Follow-up", incident.followUp, code: "05"))
                \(card("References", incident.referenceNumbers, code: "REF"))
              </section>
              <section class="section-title"><span>Evidence</span><small>\(incident.evidence.count) attachment(s)</small></section>
              \(evidence)
            </section>
            """
        }

        return documentShell(
            title: "Incident Review Packet",
            subtitle: "A factual record of incidents, impact, response, and evidence.",
            body: body
        )
    }

    @MainActor
    private static func evidenceHTML(_ incident: IncidentRecord, store: IncidentStore) throws -> String {
        if incident.evidence.isEmpty {
            return "<div class=\"empty\">No evidence attached to this incident.</div>"
        }

        var html = "<section class=\"evidence-grid\">"
        for item in incident.evidence {
            let url = store.evidenceURL(for: item, incidentID: incident.id)
            let data = try Data(contentsOf: url)
            let ext = url.pathExtension
            let type = UTType(filenameExtension: ext)
            let mime = type?.preferredMIMEType ?? "application/octet-stream"
            let b64 = data.base64EncodedString()
            let verified = store.verifyEvidence(item, incidentID: incident.id)
            let media: String
            if type?.conforms(to: .image) == true {
                media = "<img class=\"evidence-img\" src=\"data:\(mime);base64,\(b64)\" alt=\"\(escape(item.originalName))\">"
            } else {
                media = "<a class=\"file-link\" href=\"data:\(mime);base64,\(b64)\" download=\"\(escapeAttribute(item.originalName))\">Open embedded evidence file</a>"
            }

            html += """
            <article class="evidence-card">
              \(media)
              <div class="evidence-meta">
                <h3>\(escape(item.originalName))</h3>
                <p>Imported \(escape(item.importedAt.formatted(date: .abbreviated, time: .shortened)))</p>
                <p class="hash">SHA-256 \(item.sha256)</p>
                <p class="\(verified ? "verified" : "warning")">\(verified ? "Hash verified at export" : "WARNING: current file hash does not match the recorded hash")</p>
                \(item.note.isEmpty ? "" : "<p class=\"note\">\(escape(item.note))</p>")
              </div>
            </article>
            """
        }
        html += "</section>"
        return html
    }

    private static func hero(for incident: IncidentRecord) -> String {
        let tags = incident.tags.map { "<span class=\"pill\">\(escape($0))</span>" }.joined()
        return """
        <header class="incident-hero">
          <div>
            <div class="eyebrow">\(escape(incident.category.uppercased()))</div>
            <h2>\(escape(incident.title))</h2>
            <div class="pills">
              <span class="pill severity">\(escape(incident.severity.rawValue)) severity</span>
              <span class="pill">\(escape(incident.status.rawValue))</span>
              \(tags)
            </div>
          </div>
          <div class="dates">
            <b>Occurred</b><span>\(escape(incident.occurredAt.formatted(date: .abbreviated, time: .shortened)))</span>
            <b>Last modified</b><span>\(escape(incident.modifiedAt.formatted(date: .abbreviated, time: .shortened)))</span>
          </div>
        </header>
        """
    }

    private static func card(_ title: String, _ text: String, code: String, muted: Bool = false) -> String {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Not recorded." : text
        return """
        <article class="card \(muted ? "muted-card" : "")">
          <div class="card-code">\(escape(code))</div>
          <div><h3>\(escape(title))</h3><p>\(escape(value).replacingOccurrences(of: "\n", with: "<br>"))</p></div>
        </article>
        """
    }

    private static func documentShell(title: String, subtitle: String, body: String) -> String {
        """
        <!doctype html>
        <html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
        <title>\(escape(title))</title>
        <style>
        :root{--bg:#07111d;--panel:#0d1d2c;--raised:#12283a;--line:#26394a;--text:#f4f7fb;--muted:#9fb1c2;--gold:#ffba2d;--blue:#0878ff;--warn:#ff6158}
        *{box-sizing:border-box} body{margin:0;background:var(--bg);color:var(--text);font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
        .page{max-width:1180px;margin:auto;padding:46px}.brand{display:flex;align-items:center;gap:18px;border-bottom:1px solid var(--line);padding-bottom:24px;margin-bottom:28px}
        .mark{width:56px;height:56px;border:2px solid #fff;clip-path:polygon(50% 0,93% 25%,93% 75%,50% 100%,7% 75%,7% 25%);display:grid;place-items:center;color:var(--gold);font-weight:800}
        h1,h2,h3,p{margin-top:0} h1{font-size:30px;margin-bottom:3px}.brand p,.dates span,.eyebrow,.section-title small{color:var(--muted)}
        .incident-hero{display:flex;justify-content:space-between;gap:30px;padding:25px;background:linear-gradient(135deg,var(--panel),#0b2134);border:1px solid var(--line);border-radius:16px;margin-bottom:20px}
        .incident-hero h2{font-size:25px;line-height:1.25;margin:5px 0 14px}.eyebrow{font-size:11px;letter-spacing:.14em;font-weight:800}.pills{display:flex;gap:7px;flex-wrap:wrap}.pill{padding:5px 9px;border:1px solid var(--line);border-radius:999px;background:#152b3d;font-size:12px}.severity{border-color:#6a551d;color:#ffd66d}
        .dates{min-width:190px;display:grid;grid-template-columns:auto 1fr;gap:5px 10px;align-content:start;font-size:12px}.grid{display:grid;gap:14px;margin:14px 0}.grid.two{grid-template-columns:1fr 1fr}
        .card{display:grid;grid-template-columns:48px 1fr;gap:14px;background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:18px;break-inside:avoid}.card-code{width:42px;height:42px;border-radius:10px;background:#142b3e;color:var(--gold);display:grid;place-items:center;font-size:11px;font-weight:900;letter-spacing:.07em}.card h3{font-size:14px;margin-bottom:6px}.card p{color:#dbe4ec;margin:0;white-space:normal}.muted-card{border-style:dashed}
        .section-title{display:flex;justify-content:space-between;align-items:end;margin:27px 0 10px;font-size:18px;font-weight:800}.section-title small{font-size:12px;font-weight:500}
        .evidence-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}.evidence-card{background:var(--panel);border:1px solid var(--line);border-radius:14px;overflow:hidden;break-inside:avoid}.evidence-img{width:100%;max-height:400px;object-fit:contain;background:#02070d}.evidence-meta{padding:16px}.evidence-meta h3{font-size:14px;margin-bottom:5px}.evidence-meta p{font-size:12px;color:var(--muted);margin:3px 0}.hash{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;overflow-wrap:anywhere}.verified{color:#77d59c!important}.warning{color:var(--warn)!important}.note{border-top:1px solid var(--line);padding-top:9px;margin-top:9px!important;color:#dbe4ec!important}.file-link{display:block;margin:18px;color:#79b9ff}.empty{padding:20px;border:1px dashed var(--line);border-radius:12px;color:var(--muted)}
        .summary-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:30px}.metric{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:18px}.metric b{display:block;font-size:28px;color:var(--gold)}.metric span{color:var(--muted);font-size:12px}.record-break{margin:34px 0 50px;padding-top:25px;border-top:2px solid var(--line)}
        .footer{border-top:1px solid var(--line);margin-top:40px;padding-top:18px;color:var(--muted);font-size:11px;display:flex;justify-content:space-between}
        @media(max-width:800px){.page{padding:20px}.grid.two,.evidence-grid,.summary-grid{grid-template-columns:1fr}.incident-hero{display:block}.dates{margin-top:18px}}
        @media print{body{background:white;color:#111}.page{max-width:none;padding:0}.brand,.incident-hero,.card,.evidence-card,.metric{background:white!important;color:#111;border-color:#bbb}.card p,.evidence-meta p,.brand p,.dates span,.eyebrow,.section-title small{color:#444}.record-break{break-before:page}.record-break:first-of-type{break-before:auto}.file-link{display:none}}
        </style></head>
        <body><main class="page">
          <div class="brand"><div class="mark">ES</div><div><h1>\(escape(title))</h1><p>\(escape(subtitle))</p></div></div>
          \(body)
          <footer class="footer"><span>Entropy Shield Incident Tracker</span><span>Generated \(escape(Date().formatted(date: .long, time: .shortened)))</span></footer>
        </main></body></html>
        """
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private static func escapeAttribute(_ text: String) -> String { escape(text) }

    private static func safeFilename(_ text: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let mapped = text.prefix(60).unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : Character("-") }
        return String(mapped).replacingOccurrences(of: "--", with: "-")
    }

    private static func dateStamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
}
