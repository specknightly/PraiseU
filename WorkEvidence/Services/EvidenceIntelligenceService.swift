import Foundation
import AppKit
@preconcurrency import Vision
import PDFKit
import FoundationModels
import ImageIO

/// Resource limits intentionally tuned for Apple-silicon laptops with 16 GB unified memory.
/// The on-device model, graphics, OCR and macOS all share the same memory pool, so the app
/// prefers bounded working sets over maximum parallelism.
enum M3ResourcePolicy {
    static let maxOCRDimension = 2200
    static let maxPDFPages = 12
    static let maxExtractedCharacters = 9000
    static let maxEvidenceAttachmentsPerPass = 8
    static let maxEvidenceCharactersPerAttachment = 2600
    static let maxEvidencePromptCharacters = 14000

    static var profileDescription: String {
        let gib = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824.0
        return String(format: "Apple silicon efficiency profile · %.0f GB unified memory · sequential AI", gib)
    }
}

struct ProfessionalIntelligenceResult: Sendable {
    let claimStrength: Int
    let workLevel: WorkLevel
    let analysis: String
}

struct EvidenceAttachmentInput: Sendable {
    let originalFilename: String
    let relativePath: String
}

struct EvidenceAnalysisInput: Sendable {
    let title: String
    let outcome: String
    let businessImpact: String
    let attachments: [EvidenceAttachmentInput]
}

struct ProfessionalIntelligenceInput: Sendable {
    let title: String
    let context: String
    let actionTaken: String
    let outcome: String
    let businessImpact: String
    let metrics: String
    let stakeholders: String
    let responsibilityScope: ResponsibilityScope
    let evidenceAnalysis: String?
    let attachmentCount: Int
}

enum EvidenceIntelligenceService {
    static func extractedText(from attachment: EvidenceAttachmentInput) async -> String {
        guard let url = AttachmentStore.url(for: attachment.relativePath) else { return "" }
        let ext = url.pathExtension.lowercased()

        if ["txt", "md", "csv", "json", "log"].contains(ext) {
            return limited((try? String(contentsOf: url, encoding: .utf8)) ?? "", to: M3ResourcePolicy.maxExtractedCharacters)
        }

        if ext == "pdf", let pdf = PDFDocument(url: url) {
            var text = ""
            let pageLimit = min(pdf.pageCount, M3ResourcePolicy.maxPDFPages)
            for index in 0..<pageLimit {
                autoreleasepool {
                    if let page = pdf.page(at: index), let pageText = page.string {
                        text += pageText + "\n"
                    }
                }
                if text.count >= M3ResourcePolicy.maxExtractedCharacters { break }
            }
            return limited(text, to: M3ResourcePolicy.maxExtractedCharacters)
        }

        if ["png", "jpg", "jpeg", "heic", "heif", "tif", "tiff", "bmp", "webp"].contains(ext),
           let cgImage = downsampledImage(at: url, maxDimension: M3ResourcePolicy.maxOCRDimension) {
            return await recognizeText(in: cgImage)
        }
        return ""
    }

    /// ImageIO creates a thumbnail without decoding the full-resolution source into unified memory.
    /// This matters for screenshots and phone photos that can otherwise consume tens of MB each.
    private static func downsampledImage(at url: URL, maxDimension: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: false
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    private static func recognizeText(in image: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                autoreleasepool {
                    let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                    let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                    continuation.resume(returning: limited(text, to: M3ResourcePolicy.maxExtractedCharacters))
                }
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]
            DispatchQueue.global(qos: .utility).async {
                autoreleasepool {
                    let handler = VNImageRequestHandler(cgImage: image)
                    try? handler.perform([request])
                }
            }
        }
    }

    @MainActor
    static func analyzeEvidence(input: EvidenceAnalysisInput) async throws -> String {
        let availability = AppleIntelligenceEnrichmentService.availability
        guard availability.isAvailable else { throw AppleIntelligenceEnrichmentError.unavailable(availability) }

        // Deliberately sequential: the on-device model and OCR share unified memory.
        var chunks: [String] = []
        chunks.reserveCapacity(min(input.attachments.count, M3ResourcePolicy.maxEvidenceAttachmentsPerPass))
        for attachment in input.attachments.prefix(M3ResourcePolicy.maxEvidenceAttachmentsPerPass) {
            let text = await extractedText(from: attachment)
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                chunks.append("FILE: \(attachment.originalFilename)\n\(text.prefix(M3ResourcePolicy.maxEvidenceCharactersPerAttachment))")
            }
        }
        guard !chunks.isEmpty else { throw AppleIntelligenceEnrichmentError.insufficientDetail }

        let session = LanguageModelSession(model: .default, tools: []) {
            """
            You are an evidence analyst. Determine what attached workplace evidence actually supports. Never invent praise, outcomes, metrics, dates, or identities. Distinguish direct corroboration from inference. Detect explicit recognition or thanks only when the extracted text truly contains it.
            """
        }
        let response = try await session.respond(to: Prompt("""
        ACCOMPLISHMENT: \(input.title)
        CLAIMED OUTCOME: \(input.outcome.prefix(1000))
        CLAIMED IMPACT: \(input.businessImpact.prefix(1000))

        EXTRACTED EVIDENCE:
        \(chunks.joined(separator: "\n\n").prefix(M3ResourcePolicy.maxEvidencePromptCharacters))

        Use exactly these headings:
        Directly corroborated
        Recognition detected
        Evidence gaps
        Useful facts to cite

        Keep it concise. If praise is present, quote no more than a short phrase and identify it as direct evidence. If none is present, say none detected.
        """))
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor
    static func professionalIntelligence(input: ProfessionalIntelligenceInput, coreRoleDefinition: String) async throws -> ProfessionalIntelligenceResult {
        let availability = AppleIntelligenceEnrichmentService.availability
        guard availability.isAvailable else { throw AppleIntelligenceEnrichmentError.unavailable(availability) }

        let evidenceSummary = input.evidenceAnalysis ?? "No extracted evidence analysis yet."
        let session = LanguageModelSession(model: .default, tools: []) {
            """
            You are a skeptical professional-evidence analyst. Your job is to assess what can credibly be proven, not to flatter the employee. Separate stated facts from inference. Prefer conservative scores when evidence is thin.
            """
        }
        let response = try await session.respond(to: Prompt("""
        CORE ROLE BASELINE: \(coreRoleDefinition.prefix(1500))
        TITLE: \(input.title.prefix(400))
        CONTEXT: \(input.context.prefix(1300))
        ACTIONS: \(input.actionTaken.prefix(1600))
        OUTCOME: \(input.outcome.prefix(1100))
        IMPACT: \(input.businessImpact.prefix(1100))
        METRICS: \(input.metrics.prefix(650))
        STAKEHOLDERS: \(input.stakeholders.prefix(500))
        SCOPE: \(input.responsibilityScope.rawValue)
        EVIDENCE FILE COUNT: \(input.attachmentCount)
        EVIDENCE ANALYSIS: \(evidenceSummary.prefix(2600))

        First two lines MUST be:
        CLAIM_STRENGTH: <integer 0-100>
        WORK_LEVEL: <ROUTINE|ADVANCED|SPECIALIST|PROJECT_OWNER|STRATEGIC>

        Then use exactly these headings:
        Contribution
        Impact
        Scope and responsibility drift
        Demonstrated capabilities
        Counterfactual value
        Organizational reach
        Challenge my case
        Strongest defensible claim
        Missing evidence

        Explain why the work level fits. Treat counterfactuals as likelihoods, never facts.
        """))
        let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw AppleIntelligenceEnrichmentError.emptyResponse }
        let lines = text.components(separatedBy: .newlines)
        let scoreLine = lines.first(where: { $0.uppercased().hasPrefix("CLAIM_STRENGTH:") }) ?? ""
        let score = Int(scoreLine.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) ?? "") ?? 0
        let levelLine = lines.first(where: { $0.uppercased().hasPrefix("WORK_LEVEL:") })?.uppercased() ?? ""
        let level: WorkLevel
        if levelLine.contains("STRATEGIC") { level = .strategic }
        else if levelLine.contains("PROJECT_OWNER") { level = .projectOwner }
        else if levelLine.contains("SPECIALIST") { level = .specialist }
        else if levelLine.contains("ADVANCED") { level = .advanced }
        else { level = .routine }
        return ProfessionalIntelligenceResult(claimStrength: max(0, min(100, score)), workLevel: level, analysis: text)
    }

    private static func limited(_ value: String, to maxCharacters: Int) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxCharacters else { return trimmed }
        let end = trimmed.index(trimmed.startIndex, offsetBy: maxCharacters)
        return String(trimmed[..<end]) + "…"
    }
}
