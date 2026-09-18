# Entropy Shield WorkRecord v2.0.0

**IT Career Insurance you didn’t know you needed in the age of AI.**

Entropy Shield WorkRecord is a local-first macOS application for building an evidence-backed record of your professional value **and** the difficult moments that can put that value into question. It combines two complementary records in one app:

- **Accomplishments** — what you delivered, improved, automated, protected, recovered, led, or made possible, with evidence you can use in performance reviews and promotion discussions.
- **Incidents** — factual documentation of workplace events, disputes, failures, escalations, complaints, or other situations where someone may be unhappy with you and an accurate record matters.

The goal is simple: help you keep the receipts for your career. In an era where AI can answer many of the hard technical questions instantly and does not ask for a Senior Systems Administrator salary, technical knowledge by itself can increasingly become a “so what?” moment. WorkRecord helps preserve the part AI cannot retroactively reconstruct for you: the evidence of what **you** did, the context and judgment you brought, the impact you created, and the record of what actually happened when your work or decisions are challenged.

WorkRecord uses Apple Intelligence locally on supported Macs to generate conservative, evidence-aware professional and incident insights. Analysis stays on-device through Apple’s Foundation Models framework; the app is designed to avoid remote AI APIs, cloud analytics, and silent AI edits to the underlying record.

Use it to protect two sides of the same career story: **keep your job when the story gets disputed, and build the evidence for the promotion when your work deserves recognition.**

## Core principles

- **Facts and interpretation stay separate.** The editor has distinct fields for directly observed/reported facts and contextual interpretation.
- **Evidence remains inspectable.** Attached files are copied into the local incident store, assigned a recorded import time, and hashed with SHA-256.
- **AI never silently changes the record.** Apple Intelligence can analyze an incident or draft neutral factual wording, but applying the rewrite requires an explicit user action.
- **Reports preserve context.** HTML exports show incident details and evidence together instead of producing a detached summary that loses the receipts.
- **History should survive ordinary mistakes.** The JSON database is written atomically and the tracker automatically keeps the 25 most recent pre-save database snapshots.

## Features

### Incident records

Each record supports:

- Title
- Occurred date/time
- Recorded/discovered date/time
- Severity: Low, Moderate, High, Critical
- Status: Draft, Open, Monitoring, Resolved, Closed
- Category and tags
- Pinning
- Observed facts / what happened
- Context / interpretation
- Impact
- Response / what I did
- Resolution / outcome
- Follow-up / next step
- Location / system
- People involved
- Witnesses / corroboration
- Ticket, email, case, or change references
- Working notes

### Evidence

Attach screenshots, PDFs, exported emails, logs, ticket files, photos, and other source material.

For each attachment the app stores:

- Original file name
- Local copied file
- Import timestamp
- File size
- SHA-256 hash
- Optional provenance/note
- Current hash verification state

The **Open** and **Reveal** buttons let you inspect the actual copied evidence file.

### Incident AI

When the Mac supports Apple Intelligence and the local Foundation Models framework is available, Incident AI can:

- Summarize the incident without inventing facts
- Identify the supported chronology / causal sequence
- Analyze operational impact
- Highlight the response taken and where human judgment mattered
- Surface missing documentation or ambiguity
- Suggest follow-up questions/actions
- Identify pattern signals worth comparing across incidents
- Draft a more neutral version of the observed-facts narrative

The neutral draft is never applied automatically.

### Reports and patterns

The report view shows:

- Total incidents
- Open / monitoring incidents
- Critical / high-severity incidents
- Incidents with evidence
- AI-enriched incidents
- Category distribution
- Severity distribution
- Repeated exact location/system labels
- Open incidents that contain follow-up actions

### HTML exports

Two export modes are available:

- **Export Incident** from an individual incident
- **Export Review Packet** for the current filtered incident set

Exports use the Entropy Shield dark charcoal / matte-gold visual language and embed image evidence directly in the HTML. Other evidence types are embedded as self-contained data links. Each evidence card includes the recorded SHA-256 hash and whether that hash still verifies at export time.

AI output is visually separated and labeled as non-evidentiary.

## Local storage

The app stores its data under:

`~/Library/Application Support/EntropyShield/IncidentTracker/`

The structure is:

```text
IncidentTracker/
├── incidents.json
├── Backups/
│   └── incidents-YYYYMMDD-HHMMSS-SSS.json
└── Evidence/
    └── <incident UUID>/
        └── <copied evidence files>
```

No cloud-sync or network layer is implemented.

## Build in Xcode

Recommended environment:

- macOS 15 or later for the core application
- macOS 26 or later for Incident AI
- Xcode 27 recommended for the current Foundation Models SDK

### Easiest development build

1. Open `Package.swift` in Xcode.
2. Select the `IncidentTracker` executable scheme.
3. Select **My Mac** as the run destination.
4. Build and Run.

The Foundation Models code is compile-gated with `canImport(FoundationModels)` and runtime-gated for macOS 26+.

## Build a standalone .app locally

A helper script is included:

`Build-App.command`

It performs a release SwiftPM build, creates `build/Incident Tracker.app`, writes a minimal Info.plist, ad-hoc signs the app, and opens the result.

Run from Terminal:

```bash
cd /path/to/EntropyShield-IncidentTracker-v1.0.1
./Build-App.command
```

If macOS strips the executable bit after extracting the ZIP:

```bash
chmod +x Build-App.command
./Build-App.command
```

## Validation performed in the generated package

- Every Swift source file passes `swiftc -parse` under Swift 6.2.1.
- `Package.swift` is accepted by SwiftPM and the target/source layout is valid.
- The pure Foundation incident model passes Linux Swift type-checking.

A full AppKit/SwiftUI/FoundationModels link build cannot be performed in the generation environment because it does not contain the macOS SDK or Xcode. Build the package once in Xcode 27 on the Mac before treating the release as production-ready.

## Product identity

**Entropy Shield WorkRecord**  
*IT Career Insurance for the age of AI.*

**Document the wins. Preserve the facts. Keep the evidence.**

WorkRecord is the successor to the standalone PraiseU / Accomplishment Tracker experience. The accomplishment workflow is retained and expanded alongside incident tracking, unified work intelligence, evidence handling, review preparation, and local Apple Intelligence analysis.
## v2.0.0 — Work Intelligence Assistant

WorkRecord now includes a conversational assistant over the complete local evidence system.

- Ask questions across incidents, accomplishments, Work Graph entities, prevention records, operational burden, evidence metadata, and the current role baseline.
- Retrieval is deterministic and bounded before Apple Intelligence is invoked.
- **Preview Sources** shows the exact local records selected for the question.
- Sources can be deselected before the model receives context.
- Explicit Work Graph relationships and current-record context outrank loose keyword similarity.
- Every answer is instructed to cite the supplied local records as **[S1]**, **[S2]**, and so on.
- Answers separate direct support, interpretation, limitations, and useful next questions.
- Prior conversation is used only for follow-up intent; it is never treated as new evidence.
- The assistant can be opened globally or anchored to the currently selected incident/accomplishment.
- Attachment names, hashes, notes, and import metadata can participate in provenance; attachment contents are not silently read.
- Conversation history is in-memory by default and is not added to the WorkRecord database.
- Transcript export is explicit and refuses destinations inside Git working trees.
- Apple Intelligence remains on-device through Foundation Models when supported.

See [RELEASE-v2.0.0.md](RELEASE-v2.0.0.md).

## v1.9.1 — Modern Dark / Matte-Gold Theme

WorkRecord now uses a dark-only visual system inspired by modern operational and financial dashboards.

- Forced Dark Aqua appearance across the main window, Settings, and Quick Capture.
- Replaced the legacy navy/bright-blue palette with neutral charcoal and near-black surfaces.
- Pale/matte gold is now the sole primary accent family.
- Selected mode controls use matte gold with dark text for clear contrast.
- Sidebar selections use subtle gold-tinted surfaces and borders instead of solid blue blocks.
- Incident and accomplishment list selections use dark cards with pale-gold emphasis.
- Editor tabs and status icons use the same matte-gold hierarchy.
- Panels use subtle depth, low-contrast gold borders, and restrained shadows.
- The visual refresh does not alter any career-data schema or storage behavior.
- The external visual reference used to guide the design is not included in the source repository.

See [RELEASE-v1.9.1.md](RELEASE-v1.9.1.md).

## v1.9.0 — Responsibility Drift Observatory

WorkRecord can now compare documented work against a dated role baseline and show how the real job diverges from the written job.

- Replaced the unreliable macOS segmented Mode picker with explicit **Incidents** and **Accomplishments** buttons.
- Save versioned role-baseline snapshots with role title, role definition, effective date, and expected adjacent-work allowance.
- Incidents, accomplishments, prevention records, and operational-burden records can all be explicitly classified as **Core Role**, **Other / Scope Drift**, or **Unclassified**.
- The Observatory shows a month-by-month drift timeline using classified evidence.
- Record-count percentages are labeled as **evidence mix**, not time allocation.
- Measured and estimated out-of-role burden remain separate.
- Repeated links to systems/projects create inspectable de facto ownership signals without claiming formal accountability.
- Higher-level out-of-role accomplishments are surfaced separately from simple record volume.
- Export an evidence-backed Responsibility Drift packet for role/title, staffing, compensation, promotion, or reclassification discussions.
- Local Apple Intelligence can build a skeptical review brief while preserving the difference between fact, user classification, measurement, estimate, and inference.
- If no dated role baseline exists, the Observatory clearly identifies the current Settings baseline as unsnapshotted instead of presenting it as historical fact.

See [RELEASE-v1.9.0.md](RELEASE-v1.9.0.md).

## v1.8.0 — Operational Burden Intelligence

WorkRecord can now measure where operational time and attention are actually going.

- New local **Operational Burden** database with rolling backups.
- Capture active work time, recovery time, after-hours work, interruptions, and context switches.
- Separate **Measured** time from **Estimated** time everywhere.
- Record self-reported cognitive and coordination load on bounded 1–5 / 0–5 scales.
- Link burden to incidents, accomplishments, evidence, people, systems, and projects.
- Every incident and accomplishment now has a **Burden** tab.
- Global dashboard shows burden by work type and graph-linked hotspots.
- Hotspot totals explicitly warn that one record may link to multiple nodes and therefore categories can overlap.
- On-device Apple Intelligence can summarize burden patterns without judging health, competence, work ethic, or personal worth.
- After-hours minutes are treated as a subset of active time and are never double-counted.

### Source-only privacy boundary

The GitHub repository remains source-only. Live incident, accomplishment, evidence, Work Graph, prevention, and operational-burden data stays in the user's separate local WorkRecord repository.

- Runtime database/evidence paths are excluded by `.gitignore`.
- WorkRecord refuses to use a directory inside a Git working tree as its live database location.
- GitHub Actions runs a source-only privacy guard on pushes and pull requests.
- Before v1.8.0, all 30 commits reachable from `main` were audited for runtime database paths, evidence directories, and common attached-document formats; none were found.

See [DATA-PRIVACY.md](DATA-PRIVACY.md) and [RELEASE-v1.8.0.md](RELEASE-v1.8.0.md).

## v1.7.0 — Prevention & Intervention Ledger

WorkRecord now captures the work whose success often looks like “nothing happened.”

- New **Prevention & Intervention Ledger** stored separately from incidents, accomplishments, and the Work Graph.
- Track prevention, mitigation, early detection, hardening, automation, documentation, training, monitoring, process changes, and technical-debt cleanup.
- Every intervention records the risk/failure mode addressed, expected consequence, observed result, and evidence basis.
- Evidence basis is explicitly **Measured**, **Estimated**, or **Inferred**.
- Inferred entries cannot retain numeric avoided-impact claims.
- Measured and estimated avoided hours and recurrence counts are totaled separately.
- Prevention entries can link to incidents, accomplishments, evidence, people, systems, and projects.
- Every incident and accomplishment now has a **Prevention** tab.
- Local Apple Intelligence can summarize the prevention portfolio while preserving measured/estimated/inferred distinctions.
- WorkRecord does not manufacture avoided-dollar values from time estimates.

See [RELEASE-v1.7.0.md](RELEASE-v1.7.0.md).

## v1.6.0 — Contextual Recall Engine

WorkRecord can now retrieve the most relevant historical records while you are reviewing an incident or accomplishment.

- Every incident and accomplishment has a **Related History** tab.
- Explicit Work Graph relationships receive the strongest recall weight.
- Shared people, systems, projects, and evidence act as high-confidence bridge signals.
- Shared tags, category, date proximity, and bounded lexical similarity provide supporting recall signals.
- Every result displays its recall score, confidence class, and the specific reasons it was retrieved.
- Users choose which recalled records enter an **AI Context Preview**.
- The preview is bounded to keep local Apple Intelligence context predictable.
- Apple Intelligence receives recalled history only after an explicit **Analyze Selected Context** action.
- Recall scores are ranking metadata and are explicitly not treated as evidence of causation.
- Context analysis is on-device, non-evidentiary, and is not silently written into the source record.

See [RELEASE-v1.6.0.md](RELEASE-v1.6.0.md).

## v1.5.0 — Relationship-Aware Work Graph

WorkRecord now has a separate local Work Graph that connects the evidence already in the app without rewriting the source record.

- Incidents and accomplishments can be linked directly to each other.
- Evidence attachments are addressable graph nodes using their existing UUIDs and parent records.
- People, systems, and projects can be created as first-class named entities.
- Typed relationships include involvement, impact, support, evidence, project membership, prevention, response, resolution, dependency, and stakeholder context.
- Every incident and accomplishment editor now has a **Relationships** tab.
- A global **Relationship Work Graph** browser lets you search nodes, inspect links, and add context.
- Relationships persist in `WorkGraph/work-graph.json` with rolling local backups.
- The factual incident/accomplishment databases remain separate from the graph, preserving the distinction between source records and relationship context.

This is the foundation for v1.6.0 Contextual Recall: explicit user-created relationships will be treated as the highest-confidence context before inferred similarity.

See [ROADMAP.md](ROADMAP.md) and [RELEASE-v1.5.0.md](RELEASE-v1.5.0.md).

## v1.2.0 - Review adversary restored
The Accomplishments mode now restores on-device Human Value and Professional Intelligence generation and adds a dedicated Review Prep screen. `Challenge My Raise Case` intentionally argues the strongest fair case against a raise/promotion using the year's evidence, then identifies factual responses, questions, and evidence to bring to the meeting. See `PRAISEU-AUDIT-v1.2.0.md` for the full merge audit.

## v1.3.0 — Work Intelligence milestone

v1.3.0 promotes the merged Incident + Accomplishment application into a shared work-intelligence system. It adds the real Entropy Shield app icon, About page, Professional Insights, Quick Capture, Evidence Inbox/JSON/URL ingestion, OCR/PDF evidence corroboration, Brag Document, Professional Value Model, Apple Mail evidence intake, experimental Request Intelligence, and cross-mode Work Intelligence.

See `WORK-INTELLIGENCE-ASSESSMENT-v1.3.0.md` for the architectural assessment and next-stage roadmap.


## v1.3.1 — Build compatibility fix

Fixes the exhaustive-switch compile failures introduced when Review Prep, Professional Insights, and Automation & Intake were added, and hardens Vision OCR for Swift 6 concurrency checking. No data migration is required.

## v1.4.0 — User-controlled repository and settings

- Added a native Settings window with an explicit Work Record database/repository location.
- Added Link Existing Database for repository folders, `incidents.json`, or `accomplishments.json`.
- Added transactional Move Current Database with post-copy validation before switching.
- Added repository validation, record counts, size reporting, Reveal in Finder, and reset-to-default controls.
- Incidents, accomplishments, evidence, backups, and Evidence Inbox now resolve from one shared repository root.
- Added Role Baseline / expected adjacent-work settings to the unified Settings window.
- Added a functional menu-bar Quick Capture visibility preference and Evidence Inbox auto-scan preference.
- Upgraded accomplishment HTML review packets to render supported image evidence and bounded PDF previews inline.
