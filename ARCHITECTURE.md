# Architecture

## Product boundary

Accomplishment Tracker v1.8.1 is a **standalone professional-evidence module**. It does not contain the Entropy Shield Workload Evidence/Gantt module, Calendar workload integration, Dashboard Harness, or Incident Tracker.

The application is organized around four concerns:

1. **Capture**: manual entry, evidence files, Evidence Inbox, Apple Mail, JSON, and local URL capture.
2. **Evidence**: durable local records and copied supporting artifacts.
3. **Inference**: bounded local Apple Intelligence and OCR analysis.
4. **Presentation**: editor views, Professional Insights, and self-contained review exports.

## Data model

`Accomplishment` is the primary SwiftData model. `EvidenceAttachment` is a child model with cascade deletion. `RequestItem` stores prospective work requests separately from accomplishment records.

Important inferred/enrichment fields include Human Value Analysis, claim strength, work level, scope classification, career signal, evidence analysis, and generated timestamps.

## Persistence

SwiftData persists the accomplishment database locally with CloudKit disabled.

Supporting files are copied beneath the historical compatibility namespace:

`~/Library/Application Support/WorkEvidence/EvidenceFiles/<entry UUID>/`

Evidence Inbox data also uses the historical `WorkEvidence` Application Support namespace. These names are intentionally retained so users upgrading older builds keep access to existing records and evidence.

## Apple Intelligence

`AppleIntelligenceEnrichmentService` and `EvidenceIntelligenceService` use Apple's Foundation Models framework and `SystemLanguageModel.default`.

The AI paths follow several constraints:

- model availability is checked before generation;
- mutable SwiftData models are snapshotted into immutable values before async analysis;
- prompts are bounded and focused;
- fresh sessions prevent unrelated records from accumulating in one transcript;
- generated claims must remain tied to supplied evidence;
- longitudinal analysis uses sequential batches and synthesis to stay within a bounded working set.

## Evidence extraction

`EvidenceIntelligenceService` performs local extraction before model analysis:

- Vision OCR for supported images;
- PDFKit text extraction for PDFs;
- attachment count, page, character, and prompt-size limits;
- downsampled image decoding to reduce unified-memory pressure.

## Apple Mail

`AppleMailIntegrationService` uses macOS Apple Events automation to enumerate Mail accounts/mailboxes and read only explicitly selected mailboxes.

Two independent lanes are supported:

- **Evidence intake** for retrospective accomplishment evidence.
- **Request Intelligence** for prospective incoming requests.

Processed Mail message IDs are retained locally to prevent duplicate ingestion. Mail passwords and provider OAuth credentials are not stored by Accomplishment Tracker.

## Request Intelligence

`RequestIntelligenceService` analyzes a bounded request snapshot and retrieves a small set of relevant prior accomplishments through local lexical/context scoring. Only the strongest matches are promoted into active model context.

The generated response remains an editable draft. The application does not automatically send mail or promise work on the user's behalf.

## Ingestion

`IngestionService` supports:

- an application-owned Evidence Inbox;
- structured JSON intake;
- `accomplishmenttracker://capture` URL capture;
- bounded activation scans.

Capture and inference are intentionally separated so incoming material can be stored cheaply before optional AI processing.

## Reports

`ExportService` creates escaped, printable, self-contained HTML. Supported images are embedded inline, PDFs receive embedded previews, and other evidence files are retained as embedded open/save links when possible.

Annual reports, brag documents, and Professional Value Models are generated locally.

## No remote AI dependency

The application intentionally contains no remote language-model client, analytics SDK, telemetry SDK, or CloudKit-backed data synchronization. Apple Intelligence runs through the operating system's on-device Foundation Models framework.

## macOS permissions

The sandbox enables:

- user-selected file read/write for import/export;
- Apple Events automation for Mail integration.

`NSAppleEventsUsageDescription` explains the Mail access request to the user.

## Resource strategy

The M3/16 GB profile treats unified memory as a shared budget across macOS, SwiftUI, Vision, PDFKit, SwiftData, GPU work, and Foundation Models. Heavy operations are sequential and bounded to prevent avoidable memory-pressure spikes.
