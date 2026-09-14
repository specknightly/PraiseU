import Foundation

struct ExportService {
    /// Files larger than this are never inlined as base64 into exported HTML; a single large
    /// attachment could otherwise blow the export up to hundreds of MB.
    static let maxEmbeddedAttachmentBytes: Int64 = 20 * 1_024 * 1_024
    /// Total embedded-evidence size above which the UI should warn before exporting.
    static let recommendedExportWarningBytes: Int64 = 150 * 1_024 * 1_024

    static func annualReviewHTML(entries: [Accomplishment], year: Int) -> String {
        let sorted = entries.sorted { $0.date > $1.date }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        let categoryGroups = Dictionary(grouping: sorted, by: { $0.category.rawValue })
        let categorySummary = categoryGroups.keys.sorted().map { category in
            "<span class=\"pill\">\(escape(category)) · \(categoryGroups[category]?.count ?? 0)</span>"
        }.joined(separator: " ")

        let evidenceFileCount = sorted.reduce(0) { $0 + $1.attachments.count }
        let classified = sorted.filter { $0.responsibilityScope != .unclassified }
        let otherCount = classified.filter { $0.responsibilityScope == .other }.count
        let observedOtherPercent = classified.isEmpty ? 0 : Int((Double(otherCount) / Double(classified.count) * 100).rounded())

        let cards = sorted.map { entry in
            let tags = entry.tags.map { "<span class=\"tag\">\(escape($0))</span>" }.joined(separator: " ")
            let attachmentGallery = evidenceGallery(for: entry.attachments)

            return """
            <article class="entry">
              <div class="entry-head">
                <div>
                  <div class="date">\(escape(dateFormatter.string(from: entry.date))) · \(escape(entry.category.rawValue))</div>
                  <h2>\(escape(entry.title.isEmpty ? "Untitled accomplishment" : entry.title))</h2>
                </div>
                \(entry.isPinned ? "<div class=\"star\">★</div>" : "")
              </div>
              \(section("Situation / Context", entry.context))
              \(section("What I Did", entry.actionTaken))
              \(section("Outcome", entry.outcome))
              \(section("Organizational Impact", entry.businessImpact))
              \(section("Metrics", entry.metrics))
              \(section("Supporting Evidence", entry.evidenceNotes))
              \(section("Why Human Judgment Mattered", entry.humanValueAnalysis ?? ""))
              \(section("Responsibility Scope", entry.responsibilityScope.rawValue))
              \(section("Scope Drift & Career Signal", entry.scopeInference ?? ""))
              \(section("Work Level", entry.workLevel.rawValue))
              \(section("Claim Strength", entry.claimStrength.map { "\($0)/100" } ?? ""))
              \(section("Professional Intelligence", entry.professionalIntelligence ?? ""))
              \(section("Evidence Analysis", entry.evidenceAnalysis ?? ""))
              \(section("Stakeholders", entry.stakeholders))
              \(tags.isEmpty ? "" : "<div class=\"tags\">\(tags)</div>")
              \(attachmentGallery)
            </article>
            """
        }.joined(separator: "\n")

        return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Accomplishment Tracker · \(year)</title>
          <style>
            :root { color-scheme: light; --ink:#111827; --muted:#667085; --line:#d0d5dd; --paper:#ffffff; --wash:#f8fafc; --accent:#1d4ed8; --evidence:#eef5ff; }
            * { box-sizing:border-box; }
            body { margin:0; font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif; color:var(--ink); background:#eef2f6; }
            main { max-width:1100px; margin:40px auto; padding:0 24px 64px; }
            header { padding:36px; border-radius:22px; background:var(--ink); color:white; margin-bottom:24px; }
            h1 { margin:0 0 8px; font-size:38px; letter-spacing:-.03em; }
            header p { margin:0; color:#cbd5e1; }
            .summary { margin-top:20px; display:flex; flex-wrap:wrap; gap:8px; }
            .pill { padding:6px 10px; border:1px solid #475569; border-radius:999px; color:#e2e8f0; font-size:12px; }
            .entry { background:var(--paper); border:1px solid var(--line); border-radius:18px; padding:26px; margin:16px 0; }
            .entry-head { display:flex; justify-content:space-between; gap:20px; align-items:flex-start; }
            .date { color:var(--accent); text-transform:uppercase; letter-spacing:.08em; font-size:11px; font-weight:700; }
            h2 { margin:5px 0 18px; font-size:24px; letter-spacing:-.02em; }
            h3 { margin:18px 0 5px; font-size:12px; text-transform:uppercase; letter-spacing:.08em; color:var(--muted); }
            p { margin:0; white-space:pre-wrap; }
            .star { font-size:22px; }
            .tags { margin-top:18px; display:flex; gap:6px; flex-wrap:wrap; }
            .tag { font-size:12px; background:var(--wash); border:1px solid var(--line); border-radius:999px; padding:4px 8px; }
            .evidence-block { margin-top:24px; padding-top:20px; border-top:2px solid var(--line); }
            .evidence-title { display:flex; align-items:baseline; justify-content:space-between; gap:16px; margin-bottom:12px; }
            .evidence-title h3 { margin:0; color:var(--ink); font-size:13px; }
            .evidence-title span { color:var(--muted); font-size:12px; }
            .evidence-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(280px,1fr)); gap:14px; }
            figure.evidence-item { margin:0; border:1px solid var(--line); border-radius:14px; overflow:hidden; background:var(--wash); break-inside:avoid; }
            .evidence-preview { min-height:120px; display:flex; align-items:center; justify-content:center; background:var(--evidence); }
            .evidence-preview img { width:100%; height:auto; max-height:720px; object-fit:contain; display:block; background:white; }
            .evidence-preview iframe { width:100%; height:520px; border:0; background:white; }
            figcaption { padding:10px 12px; color:var(--muted); font-size:12px; border-top:1px solid var(--line); word-break:break-word; }
            figcaption strong { color:var(--ink); font-weight:600; }
            .file-card { width:100%; padding:24px 18px; text-align:center; }
            .file-card a { color:var(--accent); font-weight:600; text-decoration:none; }
            .missing { color:#9f1239; background:#fff1f2; padding:18px; width:100%; text-align:center; }
            .open-link { display:inline-block; margin-top:5px; color:var(--accent); text-decoration:none; font-size:11px; }
            @media (max-width:700px) { .evidence-grid{grid-template-columns:1fr;} main{padding:0 12px 40px;} header{padding:24px;} .entry{padding:20px;} }
            @media print {
              body{background:white;}
              main{margin:0; max-width:none; padding:0;}
              header{border-radius:0;}
              .entry{box-shadow:none; break-inside:auto;}
              figure.evidence-item{break-inside:avoid;}
              .evidence-grid{display:block;}
              figure.evidence-item{margin:12px 0;}
              .evidence-preview img{max-height:8.2in;}
              .evidence-preview iframe{height:8in;}
            }
          </style>
        </head>
        <body>
        <main>
          <header>
            <h1>\(year) Accomplishment Tracker</h1>
            <p>\(sorted.count) documented accomplishments · \(evidenceFileCount) attached evidence files · \(observedOtherPercent)% classified as Other / scope-drift work · generated by Accomplishment Tracker</p>
            <div class="summary">\(categorySummary)</div>
          </header>
          \(cards.isEmpty ? "<article class=\"entry\"><h2>No entries for this year.</h2></article>" : cards)
        </main>
        </body>
        </html>
        """
    }

    private static func evidenceGallery(for attachments: [EvidenceAttachment]) -> String {
        guard !attachments.isEmpty else { return "" }

        let sorted = attachments.sorted { $0.addedAt < $1.addedAt }
        let items = sorted.map(evidenceItem).joined(separator: "\n")

        return """
        <section class="evidence-block">
          <div class="evidence-title">
            <h3>Attached Evidence</h3>
            <span>\(sorted.count) file\(sorted.count == 1 ? "" : "s")</span>
          </div>
          <div class="evidence-grid">\(items)</div>
        </section>
        """
    }

    private static func evidenceItem(_ attachment: EvidenceAttachment) -> String {
        let filename = escape(attachment.originalFilename)
        let size = ByteCountFormatter.string(fromByteCount: attachment.byteCount, countStyle: .file)

        guard attachment.byteCount <= maxEmbeddedAttachmentBytes else {
            return """
            <figure class="evidence-item">
              <div class="evidence-preview"><div class="file-card">Too large to embed (\(escape(size))). Open the original evidence file in Accomplishment Tracker.</div></div>
              <figcaption><strong>\(filename)</strong> · \(escape(size))</figcaption>
            </figure>
            """
        }

        guard let url = AttachmentStore.url(for: attachment.relativePath),
              let data = try? Data(contentsOf: url) else {
            return """
            <figure class="evidence-item">
              <div class="evidence-preview"><div class="missing">Evidence file unavailable</div></div>
              <figcaption><strong>\(filename)</strong> · \(escape(size))</figcaption>
            </figure>
            """
        }

        let mime = mimeType(for: attachment.originalFilename)
        let dataURI = "data:\(mime);base64,\(data.base64EncodedString())"
        let encodedURI = escape(dataURI)
        let ext = (attachment.originalFilename as NSString).pathExtension.lowercased()

        let preview: String
        if imageExtensions.contains(ext) {
            preview = "<img src=\"\(encodedURI)\" alt=\"Evidence: \(filename)\">"
        } else if ext == "pdf" {
            preview = "<iframe src=\"\(encodedURI)\" title=\"Evidence PDF: \(filename)\"></iframe>"
        } else {
            preview = """
            <div class="file-card">
              <div>Embedded evidence file</div>
              <a href="\(encodedURI)" download="\(filename)">Open or save \(filename)</a>
            </div>
            """
        }

        return """
        <figure class="evidence-item">
          <div class="evidence-preview">\(preview)</div>
          <figcaption>
            <strong>\(filename)</strong> · \(escape(size))<br>
            <a class="open-link" href="\(encodedURI)" target="_blank" rel="noopener">Open evidence at full size</a>
          </figcaption>
        </figure>
        """
    }

    private static let imageExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "webp", "heic", "heif", "tif", "tiff", "bmp"
    ]

    private static func mimeType(for filename: String) -> String {
        switch (filename as NSString).pathExtension.lowercased() {
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "heic": return "image/heic"
        case "heif": return "image/heif"
        case "tif", "tiff": return "image/tiff"
        case "bmp": return "image/bmp"
        case "pdf": return "application/pdf"
        case "txt": return "text/plain"
        case "csv": return "text/csv"
        case "json": return "application/json"
        case "doc": return "application/msword"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls": return "application/vnd.ms-excel"
        case "xlsx": return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "ppt": return "application/vnd.ms-powerpoint"
        case "pptx": return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case "zip": return "application/zip"
        // "html"/"htm" deliberately fall through here rather than declaring text/html: the figcaption's
        // "Open evidence at full size" link opens with target="_blank" and no download attribute, so a
        // text/html data: URI would render — and execute any embedded script — instead of downloading.
        default: return "application/octet-stream"
        }
    }

    private static func section(_ heading: String, _ text: String) -> String {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "" }
        return "<section><h3>\(escape(heading))</h3><p>\(escape(value))</p></section>"
    }

    static func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

extension ExportService {
    static func bragDocumentHTML(narrative: String, entries: [Accomplishment], year: Int, expectedOtherPercent: Int) -> String {
        let classified = entries.filter { $0.responsibilityScope != .unclassified }
        let otherCount = classified.filter { $0.responsibilityScope == .other }.count
        let observed = classified.isEmpty ? 0 : Int((Double(otherCount) / Double(classified.count) * 100).rounded())
        let evidenceCount = entries.reduce(0) { $0 + $1.attachments.count }
        let body = escape(narrative).replacingOccurrences(of: "\n", with: "<br>")
        return """
        <!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
        <title>\(year) Brag Document · Accomplishment Tracker</title>
        <style>
        body{margin:0;background:#eef2f6;color:#111827;font:15px/1.65 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}main{max-width:920px;margin:40px auto;padding:0 24px 60px}header{background:#111827;color:white;padding:34px;border-radius:20px}h1{margin:0 0 8px;font-size:36px}.sub{color:#cbd5e1}.metrics{display:flex;gap:10px;flex-wrap:wrap;margin-top:20px}.metric{border:1px solid #475569;border-radius:12px;padding:10px 14px}.metric b{font-size:20px;display:block}.paper{margin-top:18px;background:white;border:1px solid #d0d5dd;border-radius:18px;padding:30px}.narrative{white-space:normal}.note{margin-top:20px;color:#667085;font-size:12px}@media print{body{background:white}main{margin:0;max-width:none}header{border-radius:0}.paper{border:0;padding:20px 0}}
        </style></head><body><main><header><h1>\(year) Brag Document</h1><div class="sub">Evidence-grounded local Apple Intelligence synthesis · Accomplishment Tracker</div><div class="metrics"><div class="metric"><b>\(entries.count)</b>accomplishments</div><div class="metric"><b>\(evidenceCount)</b>evidence files</div><div class="metric"><b>\(observed)%</b>observed Other / scope-drift work</div><div class="metric"><b>\(expectedOtherPercent)%</b>expected Other work</div></div></header><section class="paper"><div class="narrative">\(body)</div><div class="note">AI synthesis is an inference layer over your records. Verify claims against the linked accomplishment evidence before external use.</div></section></main></body></html>
        """
    }
}

extension ExportService {
    static func professionalValueModelHTML(narrative: String, entries: [Accomplishment], year: Int, expectedOtherPercent: Int) -> String {
        let classified = entries.filter { $0.responsibilityScope != .unclassified }
        let other = classified.filter { $0.responsibilityScope == .other }.count
        let observed = classified.isEmpty ? 0 : Int((Double(other) / Double(classified.count) * 100).rounded())
        let scored = entries.compactMap(\.claimStrength)
        let averageStrength = scored.isEmpty ? 0 : Int((Double(scored.reduce(0,+)) / Double(scored.count)).rounded())
        let advanced = entries.filter { [.advanced,.specialist,.projectOwner,.strategic].contains($0.workLevel) }.count
        let evidence = entries.reduce(0) { $0 + $1.attachments.count }
        let body = escape(narrative).replacingOccurrences(of: "\n", with: "<br>")
        return """
        <!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
        <title>\(year) Professional Value Model · Accomplishment Tracker</title>
        <style>body{margin:0;background:#eef2f6;color:#111827;font:15px/1.65 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}main{max-width:1000px;margin:36px auto;padding:0 24px 64px}header{background:#0f172a;color:white;padding:34px;border-radius:20px}h1{margin:0;font-size:36px}.sub{color:#cbd5e1;margin-top:7px}.metrics{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px;margin-top:22px}.metric{border:1px solid #475569;border-radius:12px;padding:12px}.metric b{font-size:22px;display:block}.paper{margin-top:18px;background:white;border:1px solid #d0d5dd;border-radius:18px;padding:30px}.note{margin-top:22px;color:#667085;font-size:12px}@media print{body{background:white}main{margin:0;max-width:none}header{border-radius:0}.paper{border:0}}</style></head><body><main>
        <header><h1>\(year) Professional Value Model</h1><div class="sub">Longitudinal evidence intelligence · Accomplishment Tracker</div><div class="metrics">
        <div class="metric"><b>\(entries.count)</b>accomplishments</div><div class="metric"><b>\(evidence)</b>evidence files</div><div class="metric"><b>\(observed)%</b>observed Other work</div><div class="metric"><b>\(expectedOtherPercent)%</b>expected Other work</div><div class="metric"><b>\(advanced)</b>advanced+ records</div><div class="metric"><b>\(averageStrength)</b>avg claim strength</div>
        </div></header><section class="paper">\(body)<div class="note">This is an inference layer, not a factual source. Verify important claims against the underlying accomplishment records and evidence before external use.</div></section></main></body></html>
        """
    }
}
