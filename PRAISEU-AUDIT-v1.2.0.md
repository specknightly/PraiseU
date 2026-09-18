# PraiseU feature audit - v1.2.0

Compared against specknightly/PraiseU main branch on 2026-09-18.

## Restored in v1.2.0
- On-device Apple Intelligence Human Value Analysis.
- Professional Intelligence generation with claim-strength parsing and work-level classification.
- Per-accomplishment adversarial `Challenge my case` analysis.
- New Review Prep mode with `Challenge My Raise Case`, using the year's accomplishment corpus to build the strongest fair counterargument against a raise/promotion and prepare evidence-grounded responses.
- Editable Role Baseline used to test the `this is just your normal job` objection.

## Already present from v1.1.0
- Context/action/outcome/impact/metrics/stakeholders/tags.
- Scope classification, work level, claim strength fields.
- Human-value, scope-inference, professional-intelligence and evidence-analysis fields.
- Local evidence copying, SHA-256 verification, JSON persistence/backups.
- Accomplishment and annual review exports.

## Still not yet transplanted from PraiseU
These are intentionally listed rather than silently pretending the merge is complete:
- Professional Insights dashboard with Swift Charts.
- AI Brag Document generator.
- full longitudinal Professional Value Model generator.
- OCR/PDF evidence text extraction and AI corroboration analysis.
- menu-bar Quick Capture.
- Evidence Inbox / JSON / URL-scheme ingestion.
- Apple Mail evidence ingestion.
- experimental Request Intelligence mailbox/contextual recall/draft-response workflow.
- settings UI for role baseline, expected adjacent-work percentage, and ingestion controls.
- automatic migration/import from the standalone SwiftData PraiseU database.

The Incident Tracker visual shell remains canonical.
