# Entropy Shield WorkRecord v1.8.0

## Operational Burden Intelligence

v1.8.0 makes invisible operational load measurable without treating workload as a proxy for competence, health, or value.

## What can be captured

Operational burden records can capture:

- Active minutes consumed by the work.
- Recovery minutes required to regain working context.
- After-hours minutes.
- Interruption count.
- Context-switch count.
- Self-reported cognitive load.
- Self-reported coordination load.
- The trigger or source of the burden.
- Impact on planned work.
- The measurement or estimate basis.
- Links to incidents, accomplishments, evidence, people, systems, and projects.

Burden types include interruption/context switch, incident response, reactive support, after-hours work, coordination/follow-up, meetings/communication, repeat work/rework, maintenance/caretaking, escalation/ownership gaps, vendor/dependency work, administrative/process work, and other.

## Measured versus estimated time

Every burden entry is explicitly **Measured** or **Estimated**.

Measured time should be supported by a timer, calendar, ticket/log timestamp, meeting duration, or comparable recorded source.

Estimated time remains clearly labeled as an estimate.

The dashboard never collapses measured and estimated hours into a single proven total.

## Time accounting

Active time and recovery time are added to form captured operational burden.

After-hours time is treated as a subset of active time and is not added again. The store clamps after-hours minutes so they cannot exceed the active duration on the same record.

Negative time/count values are normalized to zero.

## Self-reported load

Cognitive load uses a 1–5 self-report scale.

Coordination load uses a 0–5 self-report scale.

These values describe how demanding the work felt to hold in context or coordinate. They are not medical data, diagnoses, objective productivity scores, or measures of competence.

## Graph-aware hotspots

Operational burden records can link to first-class Work Graph entities.

The dashboard can surface people, systems, and projects repeatedly associated with burden records and show measured/estimated minutes plus average self-reported load.

Hotspot totals can overlap because one burden record may link to multiple graph nodes. The application explicitly warns against summing hotspot categories as if they were mutually exclusive.

## Operational Burden Intelligence

The global dashboard can run a local Apple Intelligence analysis.

The model is explicitly instructed to:

- Keep measured and estimated time separate.
- Treat cognitive and coordination load as subjective self-report.
- Avoid health, burnout, mental-state, personality, competence, or work-ethic judgments.
- Avoid inferring motives of managers or coworkers.
- Avoid treating high burden as proof of high value or poor performance.
- Avoid converting time into money.
- Preserve the overlapping nature of graph hotspot totals.
- Identify what the data does not prove.

Generated analysis is non-evidentiary and is not silently written back into source records.

## Source-only GitHub privacy boundary

The GitHub repository contains application source, documentation, release metadata, and static app assets only.

Before v1.8.0, all 30 commits reachable from `main` were audited for:

- `incidents.json`
- `accomplishments.json`
- Work Graph runtime JSON
- Prevention Ledger runtime JSON
- Operational Burden runtime JSON
- Evidence directories
- Backup directories
- Evidence Inbox contents
- Common workplace attachment formats including email, PDF, Office documents, and CSV

No runtime database or evidence attachment was found.

v1.8.0 adds three enforcement layers:

1. `.gitignore` excludes runtime data and common evidence/document formats.
2. WorkRecord refuses to use a folder inside a Git working tree as its live database location.
3. A GitHub Actions privacy guard rejects tracked runtime database/evidence paths and blocked attachment formats.

The live WorkRecord database remains local under the user's selected repository, defaulting to Application Support.

## Storage

Operational burden data is stored locally at:

`OperationalBurden/operational-burden.json`

Rolling backups are stored under:

`OperationalBurden/Backups/`

No runtime database file is included in the Git source repository.

## Compatibility

- No incident schema migration.
- No accomplishment schema migration.
- No Work Graph schema migration.
- No Prevention Ledger schema migration.
- v1.7.0 local data remains compatible.
- The new OperationalBurden directory/database is created locally only when normal storage preparation occurs.

## Validation note

The branch was reviewed for local-storage separation, Git privacy boundaries, error propagation, graph references, measured/estimated accounting, and the release file set. A final AppKit/SwiftUI/FoundationModels compile and signed application test still requires Xcode and the target macOS SDK on a Mac.
