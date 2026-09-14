# Changelog

All notable standalone Accomplishment Tracker changes are recorded here.

## 1.8.2

### GitHub-ready source cleanup
- Consolidated current documentation around the standalone application.
- Added `.gitignore`, `CONTRIBUTING.md`, and a local `scripts/preflight.sh` validation helper.
- Removed stale release notes describing abandoned Outlook/Graph configuration and integrated workload/incident experiments.
- Verified all 16 Swift source files parse with Swift 6.2.1, plist/entitlements lint cleanly, and every Swift source is referenced by the Xcode project.

## 1.8.1

### Standalone stabilization
- Preserved Professional Evidence, Professional Insights, Apple Mail evidence intake, Request Intelligence, Evidence Inbox, visual reports, and local Apple Intelligence features.
- Removed Entropy Shield Workload Evidence / Gantt integration, workload bridge exports, Calendar workload module code, Dashboard Harness code, and Incident Tracker integration.
- Carried forward Swift Charts color/type-check fixes from the integration branch.
- Kept historical `WorkEvidence` persistence identifiers for upgrade compatibility.

## 1.8.0

### Request Intelligence
- Added a second Apple Mail lane for prospective work requests.
- Added local request digestion, bounded contextual recall from prior accomplishments, priority inference, and editable response drafting.

## 1.7.0

### Professional Insights and Apple Mail
- Added native Swift Charts dashboard for scope drift, work level, evidence health, category mix, claim strength, and monthly trends.
- Added selected-mailbox Apple Mail evidence ingestion and message-ID deduplication.

## 1.6.x

### Reliability and M3 optimization
- Added M3 / 16 GB bounded-memory processing.
- Added immutable Sendable snapshots for Swift 6 concurrency safety.
- Hardened actor isolation and fixed strict-concurrency build issues.
- Added Entropy Shield clock application icon and resizable Settings.

## 1.5.0

### Professional Intelligence
- Added evidence OCR/PDF extraction and conservative evidence analysis.
- Added claim strength, work level, scope/career inference, organizational reach, counterfactual value, and Challenge My Case.
- Added Evidence Inbox, structured JSON intake, and local URL capture.

## 1.4.0

### Evidence Intelligence
- Added editable role baseline and expected Other-work percentage.
- Added scope-drift inference, career-signal analysis, and AI brag-document generation.

## 1.2.0

### Visual evidence reports
- Added self-contained HTML evidence portfolios with inline screenshots, PDF previews, and embedded attachment links.

## 1.1.0

### Human Value Analysis
- Added local Apple Intelligence analysis explaining evidence-supported human contribution and where AI could augment rather than replace it.

## 1.0.0

- Initial native SwiftUI/SwiftData accomplishment journal and annual review export.
