# Entropy Shield Incident Tracker v1.1.0

## Accomplishment mode integration

The standalone Accomplishment Tracker / Work Evidence workflow is now built directly into Incident Tracker as a second top-level mode.

### Design decision

Incident Tracker remains the canonical application shell and visual language. The application now has a segmented mode control in the top bar:

- Incidents
- Accomplishments

Switching modes changes the sidebar, search scope, record list, editor, status metrics, new-record action, and export action without opening a second application.

### Accomplishment mode capabilities

- All / This Year / Pinned / Draft / Completed filters
- Category and tag filtering
- Search and sorting
- Context / challenge
- Action taken
- Outcome
- Business / operational impact
- Metrics
- Stakeholders
- Evidence notes
- Responsibility scope
- Work level
- Claim strength
- Human-value analysis
- Scope inference
- Professional intelligence
- Evidence analysis
- Evidence attachments copied locally and SHA-256 hashed
- Per-record HTML export
- Multi-record accomplishment review export
- Atomic JSON persistence and rolling backups

### Storage

Existing incident storage is unchanged:

`~/Library/Application Support/EntropyShield/IncidentTracker/incidents.json`

Accomplishments use a separate internal store beneath the same application root:

`~/Library/Application Support/EntropyShield/IncidentTracker/Accomplishments/accomplishments.json`

This keeps one application while preventing one record schema from corrupting the other.

### Compatibility

The incident JSON schema and evidence directories are unchanged. Existing Incident Tracker records therefore remain compatible with this release.

The former standalone Accomplishment Tracker used SwiftData and a separate application container. v1.1.0 does not silently modify or delete that older database.
