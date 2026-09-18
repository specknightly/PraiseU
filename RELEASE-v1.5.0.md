# Entropy Shield WorkRecord v1.5.0

## Relationship-Aware Work Graph

v1.5.0 turns the combined incident + accomplishment record into a relationship-aware evidence system.

The core design rule is that the graph is **context**, not a rewrite of history. Incident records, accomplishment records, and evidence metadata remain in their existing databases. The new Work Graph stores explicit relationships between those records and first-class people, systems, and projects.

## What changed

- Added a versioned `WorkGraph/work-graph.json` database beneath the selected WorkRecord repository root.
- Added rolling Work Graph backups under `WorkGraph/Backups/`.
- Added typed node references for incidents, accomplishments, evidence, people, systems, and projects.
- Added first-class named entities for people, systems, and projects.
- Added typed relationships with optional user notes and timestamps.
- Added a Relationships tab to incident records.
- Added a Relationships tab to accomplishment records.
- Added a global Relationship Work Graph browser.
- Added quick-create-and-link flows for people, systems, and projects.
- Added graph relationship counts to the main status bars and Settings.
- Added Work Graph validation to repository validation.
- Added the product roadmap through v2.4.0.

## Relationship model

The initial relationship vocabulary is:

- Related To
- Involves
- Affects
- Supports
- Evidence For
- Part Of
- Worked On
- Prevented / Reduced Risk
- Responded To
- Resolved / Helped Resolve
- Depends On
- Stakeholder

Relationships are directional, but the UI shows them from either side of the connection.

## Data safety and compatibility

- Existing `incidents.json` data is unchanged.
- Existing `Accomplishments/accomplishments.json` data is unchanged.
- Existing evidence files and SHA-256 metadata are unchanged.
- Opening v1.5.0 against a v1.4.1 repository creates the WorkGraph directory only when storage preparation occurs.
- No automatic relationship inference is written into the graph in v1.5.0.
- Deleting a relationship does not delete either connected record or evidence item.
- Missing/deleted source nodes can be shown as missing context rather than silently changing another record.

## Why this matters

A career record becomes more useful when it can answer not only “what happened?” but also “what was this connected to?”

The graph provides the substrate for later releases to retrieve relevant history, quantify prevention and burden, observe responsibility drift, and make AI conclusions traceable. Explicit user-created relationships are intended to become the highest-confidence recall signal before semantic or temporal inference.

## Validation

- New Work Graph source files parse successfully with Swift 6.2.1.
- Repository persistence remains JSON + atomic writes + rolling backups.
- A full AppKit/SwiftUI/FoundationModels build still requires the macOS/Xcode toolchain and should be run on the target Mac before publishing a signed binary.
