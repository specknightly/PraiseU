# Entropy Shield WorkRecord v2.0.0

## Work Intelligence Assistant

v2.0.0 adds a conversational, local-first interface over the complete WorkRecord evidence system.

The assistant is designed around a simple rule: **retrieval happens before generation, and the user can inspect the retrieval set.**

## Sources the assistant can retrieve

The bounded retrieval engine can rank:

- Incidents.
- Accomplishments.
- Incident/accomplishment evidence metadata.
- Prevention & Intervention Ledger records.
- Operational Burden records.
- People, systems, and projects from the Work Graph.
- The saved role baseline, or current Settings baseline when no dated snapshot exists.

The assistant does not automatically read arbitrary evidence-file contents.

For attachment provenance it may receive:

- Recorded file name.
- Import date.
- SHA-256.
- Evidence note.
- Byte count.
- Parent record.

## Retrieval policy

The retrieval engine is deterministic and local.

Ranking signals include:

1. Current-record anchoring.
2. Explicit Work Graph relationships.
3. Shared graph entities.
4. Direct links from prevention/burden records.
5. Query-term overlap.
6. Question intent, such as promotion, incident defense, prevention, burden, responsibility drift, or systems/projects.
7. Evidence presence and accomplishment work level where relevant.

Retrieval score means **relevance for inspection**. It is not truth confidence, causation probability, or proof of ownership.

A maximum of 12 sources is selected by default.

The source packet supplied to Apple Intelligence is capped at 22,000 characters.

## Context Inspector

Before asking Apple Intelligence, the user sees a Context Inspector containing the exact retrieved sources.

The user can:

- Inspect source type and title.
- See why each source was retrieved.
- See its retrieval class.
- Deselect any source.
- Select all or none.
- Submit only the checked records.

The model is not invoked by **Preview Sources**.

## Source-cited answers

Each current source receives a label such as:

- [S1]
- [S2]
- [S3]

The Apple Intelligence prompt requires factual claims to cite these labels inline.

Every answer uses the following sections:

- Direct answer
- What the record supports
- Interpretation
- What the record does not prove
- Useful next questions

Interpretation is explicitly separated from direct record support.

## Conversational follow-up

The assistant keeps turns in memory while its window is open.

Up to four recent turns may be supplied to Apple Intelligence to understand follow-up intent.

Previous assistant output is explicitly labeled **conversation context only** and is not allowed to become evidence for the next answer.

Source labels reset for every answer.

## Current-record assistant

The assistant can be opened globally or anchored to the current incident/accomplishment.

When anchored:

- The current record receives the strongest retrieval boost.
- Direct graph relationships receive the next strongest structured boost.
- Related records can still be retrieved from the rest of WorkRecord.

The main toolbar includes a Work Intelligence Assistant button, and the menu includes **Ask Assistant About Current Record**.

## Built-in prompts

v2.0.0 includes quick prompts for:

- Promotion evidence.
- Incident defense.
- Operational burden.
- Preventive value.
- Responsibility drift.
- Systems/projects repeatedly requiring intervention.

These are question starters only. They do not change source evidence.

## AI guardrails

The Work Intelligence model instructions require it to:

- Use only the current source packet for factual claims.
- Cite factual statements with supplied source labels.
- Never invent citation labels.
- Keep facts, user classifications, measurements, estimates, and inference separate.
- Keep measured and estimated burden separate.
- Avoid converting graph relationships into causation, motive, or formal accountability.
- Treat prevention consequences as risk statements rather than guaranteed avoided events.
- Treat scope labels as user classifications requiring corroboration for formal employment claims.
- Avoid mental-state, health, motive, personality, or competence judgments.
- Avoid inventing compensation bands, monetary savings, organizational policy, peer comparisons, or legal conclusions.
- Say when the record is insufficient.

## Conversation storage

Assistant conversations are **not** persisted automatically.

Closing/clearing the assistant removes the in-memory conversation state.

The user may explicitly export a Markdown transcript.

For privacy, transcript export is blocked if the selected destination is inside a Git working tree.

## GitHub/source privacy

v2.0.0 does not add any runtime career database to GitHub.

The release packaging workflow:

1. Checks out only the Git source tree.
2. Runs `Scripts/verify-source-only.sh`.
3. Builds the release with SwiftPM on a macOS runner.
4. Creates the release ZIP using `git archive`, which includes tracked files only.
5. Uploads the source ZIP and SHA-256 as a workflow artifact.

Runtime incidents, accomplishments, evidence files, graph data, prevention records, burden records, role-baseline snapshots, and assistant transcripts are not included.

## Compatibility

- No incident schema migration.
- No accomplishment schema migration.
- No Work Graph schema migration.
- No Prevention Ledger schema migration.
- No Operational Burden schema migration.
- No Responsibility Drift schema migration.
- No assistant conversation migration because conversations are not persisted.

## Build metadata

- Version: 2.0.0
- Build: 13
- Product: Entropy Shield Work Record

## Validation

v2.0.0 is gated by a macOS GitHub Actions workflow that runs the source-only privacy check and `swift build -c release` before creating the downloadable source ZIP.
