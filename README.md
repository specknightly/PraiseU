# Accomplishment Tracker

**Current source release: v1.8.2 Standalone**

Getting recognized for hard work is only getting harder now that AI can produce an answer in seconds. Accomplishment Tracker empowers IT professionals around the world to log the accomplishments worthy of a raise or a promotion — turning day-to-day hard work into a dated, evidence-backed record instead of something you have to reconstruct from memory the night before a review.

Accomplishment Tracker is a local-first macOS application for building a dated, evidence-backed record of professional accomplishments. It is designed for situations where annual performance reviews, promotion cases, or role-scope discussions otherwise depend too heavily on memory and subjective interpretation.

The application combines structured accomplishment records, supporting evidence, native Apple Mail intake, Swift Charts insights, and on-device Apple Intelligence analysis. It does not require the Entropy Shield Workload Evidence application, the Dashboard Harness, or the Incident Tracker.

## Highlights

- Dated accomplishment records with context, action, outcome, impact, metrics, stakeholders, tags, and evidence notes.
- Supporting screenshots, PDFs, documents, and other files copied into local application storage.
- Self-contained annual HTML review packets with visual evidence rendered inline where supported.
- Local Apple Intelligence **Human Value Analysis** explaining where human judgment, accountability, context, communication, or physical action mattered.
- **Professional Intelligence** including claim strength, work level, scope drift, career signals, organizational reach, counterfactual value, missing evidence, and an adversarial "Challenge My Case" analysis.
- **Professional Insights** dashboard using native Swift Charts for category mix, scope drift, work level, evidence coverage, claim strength, monthly momentum, and related trends.
- **Brag Document** and **Professional Value Model** generators for evidence-grounded longitudinal summaries.
- Apple Mail evidence ingestion from one explicitly selected mailbox.
- Experimental **Request Intelligence** using a second selected Apple Mail mailbox to digest incoming work requests, recall relevant prior accomplishments, and draft a response locally for review.
- Evidence Inbox, JSON intake, and the `accomplishmenttracker://capture` URL scheme for lightweight local ingestion.
- Bounded OCR and AI workloads tuned for an M3 MacBook with 16 GB unified memory.

## Privacy and data boundaries

Accomplishment Tracker is local-first:

- SwiftData persistence is local and CloudKit is disabled.
- Apple Intelligence uses Apple's on-device Foundation Models framework.
- The app contains no remote AI API or analytics/telemetry client.
- Apple Mail integration uses macOS Automation permission and reads only the mailbox selected in Settings.
- Imported evidence is copied into local Application Support storage.
- Generated reports are created locally.

This is **not** a secrets vault. Do not store passwords, private keys, authentication tokens, regulated personal data, or information your employer prohibits from being copied locally.

## Apple Mail integration

Accomplishment Tracker supports two optional Mail lanes:

1. **Evidence mailbox**: messages placed in the selected mailbox can become reviewable accomplishment drafts and supporting evidence.
2. **Request Intelligence mailbox (experimental)**: messages in a separate selected mailbox can be summarized and used to create an editable local response draft, with relevant prior accomplishments surfaced through bounded contextual recall.

macOS asks for Automation permission the first time Mail access is used. The app does not request mailbox passwords, Microsoft Graph credentials, or OAuth tokens.

## Evidence-first AI design

Generated analysis is intentionally conservative. Prompts instruct the on-device model to distinguish evidence from inference, avoid invented facts or metrics, and acknowledge when AI or automation could reasonably have performed much of the work.

The application is intended to help answer:

- What did I actually do?
- What changed because of it?
- What evidence supports that claim?
- Was the work inside or outside my expected role?
- What level of judgment or ownership did it demonstrate?
- What patterns emerge across the year?

## M3 / 16 GB resource strategy

Heavy processing uses bounded working sets:

- Images are downsampled before Vision OCR.
- OCR and Foundation Models work runs sequentially rather than creating large parallel memory spikes.
- PDF extraction is page/character bounded.
- Evidence analysis caps attachments per pass.
- Longitudinal reports use sequential map/reduce-style summarization rather than one enormous model context.
- Inbox scans are batch limited.

The objective is predictable responsiveness on a 16 GB unified-memory Mac rather than maximum concurrency for its own sake.

## Build requirements

- Xcode with a macOS 26+ SDK
- Swift 6
- macOS 26 or later; the UI is intended for macOS 27
- Apple Intelligence-capable Mac for Foundation Models features
- Apple Intelligence enabled and its on-device model available

### Build

1. Clone or download the repository.
2. Open `WorkEvidence.xcodeproj` in Xcode.
3. Select the `WorkEvidence` target/scheme.
4. Choose your Apple development team under Signing & Capabilities if required.
5. Build and run.

The Xcode project and internal target retain the historical `WorkEvidence` name for compatibility. The product displayed to users is **Accomplishment Tracker**.

## Repository layout

```text
WorkEvidence/
  App/        Application entry point
  Models/     SwiftData and request models
  Services/   AI, OCR, export, ingestion, Mail, and attachment services
  Views/      Main UI, editor, settings, insights, and Request Intelligence
  Assets.xcassets/
WorkEvidence.xcodeproj/
ARCHITECTURE.md
CHANGELOG.md
```

## Local storage compatibility

Some internal storage paths continue to use the historical `WorkEvidence` namespace. This is intentional so upgrades do not strand previously documented accomplishments or evidence files.

## License

No open-source license is included in this repository. Copyright remains with the author unless a license is added later.
