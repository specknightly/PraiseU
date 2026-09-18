# Entropy Shield Work Record v1.4.0

## Repository location controls

The application now treats its local data as one user-selectable Work Record repository root. The root contains incident records, accomplishment records, evidence, backups, and the Evidence Inbox.

Settings now provides:

- Current repository path and Reveal in Finder.
- Validate Database with incident/accomplishment counts and repository size.
- Link Existing Database by selecting a repository folder, `incidents.json`, or `accomplishments.json`.
- Move Current Database to an empty folder. The source is copied first, the destination is validated, and the app switches only after validation succeeds.
- Use Default Location to return to `~/Library/Application Support/EntropyShield/IncidentTracker` without deleting the alternate repository.

A legacy standalone PraiseU SwiftData store is intentionally not linked in place. It requires a dedicated read-only migration/import path because its persistence model is different from the unified Work Record JSON repository.

## Additional PraiseU parity improvements

- Role Baseline and expected adjacent/out-of-role percentage now live in the native Settings window.
- Quick Capture visibility is a functional setting.
- Evidence Inbox auto-scan remains configurable.
- Apple Mail evidence mailbox selection persists across launches.
- Optional Mail evidence scanning when the app becomes active uses the selected mailbox and existing message-ID deduplication.
- Accomplishment HTML review packets now embed supported image evidence and bounded PDF evidence inline, up to 20 MB per embedded file.

## Compatibility

The default repository remains the historical Incident Tracker location, so existing v1.3.1 data is loaded without migration when no custom repository has been selected.
