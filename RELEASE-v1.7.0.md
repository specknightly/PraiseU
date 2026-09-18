# Entropy Shield WorkRecord v1.7.0

## Prevention & Intervention Ledger

v1.7.0 captures preventive work that is usually invisible precisely because it succeeded.

The ledger is designed around a conservative principle: **preventive value should be documented, but an avoided event should not be presented as a fact merely because it was plausible.**

## What can be recorded

Intervention types include:

- Prevention
- Mitigation
- Early Detection
- Hardening
- Automation
- Documentation
- Training / Knowledge Transfer
- Monitoring
- Process Change
- Technical Debt / Cleanup

Each entry can record:

- Action taken.
- Risk or failure mode addressed.
- Expected consequence without the intervention.
- Observed result after the intervention.
- Measurement or estimate basis.
- Optional recurrence count avoided.
- Optional hours avoided.
- Optional people or systems protected.
- Source record and additional Work Graph links.
- Supporting notes.

## Evidence basis

Every ledger entry is classified as one of three evidence levels.

### Measured

Supported by observed counts, elapsed time, tickets, logs, before/after frequency, or other recorded evidence.

### Estimated

A user-supplied estimate with an explicit basis. The number remains an estimate.

### Inferred

A plausible preventive claim without enough evidence for numeric certainty.

When an entry is saved as **Inferred**, WorkRecord clears numeric avoided-impact fields. This prevents an inference from silently becoming a quantified fact.

## Avoided burden

The ledger reports measured and estimated totals separately:

- Measured hours avoided.
- Estimated hours avoided.
- Measured recurrences avoided.
- Estimated recurrences avoided.

These categories are intentionally never merged into a single “proven savings” number.

WorkRecord does not convert avoided hours into currency and does not invent avoided dollar value.

## Relationship-aware prevention

Prevention entries can be linked to:

- Incidents.
- Accomplishments.
- Evidence.
- People.
- Systems.
- Projects.

Incidents and accomplishments each receive a **Prevention** tab so an intervention can be created from the record that motivated it or demonstrates it.

## Prevention Intelligence

The global ledger can run an on-device Apple Intelligence summary.

The model receives the evidence basis for every claim and is explicitly instructed to:

- Preserve Measured / Estimated / Inferred distinctions.
- Never invent avoided incidents.
- Never invent money or savings.
- Never convert time to dollars.
- Treat expected consequences as risk statements rather than events that definitely would have happened.
- Identify claims that still need stronger evidence.

Generated Prevention Intelligence is labeled non-evidentiary.

## Storage

Prevention data is stored at:

`PreventionLedger/prevention-ledger.json`

Rolling backups are stored under:

`PreventionLedger/Backups/`

Repository validation now checks the ledger when it exists.

## Compatibility

- No incident schema change.
- No accomplishment schema change.
- No Work Graph schema change.
- v1.6.0 repositories open without migration; the PreventionLedger directory is created by normal storage preparation.
- Existing incident, accomplishment, evidence, relationship, and contextual-recall data remain unchanged.

## Validation note

The release was reviewed for store wiring, storage compatibility, graph references, error propagation, and Swift source structure. A final AppKit/SwiftUI/FoundationModels build and signed application test still requires Xcode and the target macOS SDK on a Mac.
