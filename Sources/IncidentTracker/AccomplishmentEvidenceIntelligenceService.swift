import Foundation
import AppKit
import PDFKit
@preconcurrency import Vision
import ImageIO

@MainActor
enum AccomplishmentEvidenceIntelligenceService {
    static func analyze(_ record: AccomplishmentRecord, store: AccomplishmentStore) async throws -> String {
        guard !record.evidence.isEmpty else { throw AccomplishmentAIError.insufficientDetail }
        var chunks:[String]=[]
        for item in record.evidence.prefix(8) {
            let url=store.evidenceURL(for:item,accomplishmentID:record.id)
            let text=await extractedText(url)
            if !text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { chunks.append("FILE: \(item.originalName)\n\(text.prefix(2600))") }
        }
        guard !chunks.isEmpty else { throw AccomplishmentAIError.insufficientDetail }
        return try await AccomplishmentAIService.evidenceCorroboration(record:record, extracted:chunks.joined(separator:"\n\n").prefix(14000).description)
    }

    private static func extractedText(_ url:URL) async -> String {
        let ext=url.pathExtension.lowercased()
        if ["txt","md","csv","json","log"].contains(ext) { return String(((try? String(contentsOf:url,encoding:.utf8)) ?? "").prefix(9000)) }
        if ext == "pdf", let pdf=PDFDocument(url:url) {
            var out=""; for i in 0..<min(pdf.pageCount,12) { if let s=pdf.page(at:i)?.string { out += s+"\n" }; if out.count>9000{break} }; return String(out.prefix(9000))
        }
        if ["png","jpg","jpeg","heic","heif","tif","tiff","bmp","webp"].contains(ext), let cg=downsample(url) { return await recognize(cg) }
        return ""
    }
    private static func downsample(_ url:URL)->CGImage? {
        guard let src=CGImageSourceCreateWithURL(url as CFURL,nil) else{return nil}
        let opts:[CFString:Any]=[kCGImageSourceCreateThumbnailFromImageAlways:true,kCGImageSourceThumbnailMaxPixelSize:2200,kCGImageSourceCreateThumbnailWithTransform:true,kCGImageSourceShouldCacheImmediately:false]
        return CGImageSourceCreateThumbnailAtIndex(src,0,opts as CFDictionary)
    }
    private static func recognize(_ image: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let request = VNRecognizeTextRequest { result, _ in
                    let observations = (result.results as? [VNRecognizedTextObservation]) ?? []
                    let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                    continuation.resume(returning: String(text.prefix(9000)))
                }
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["en-US"]
                try? VNImageRequestHandler(cgImage: image).perform([request])
            }
        }
    }
}
