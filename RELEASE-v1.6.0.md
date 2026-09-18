# Entropy Shield WorkRecord v1.6.0

## Contextual Recall Engine

v1.6.0 makes the Relationship-Aware Work Graph useful at the moment context is needed. Every incident and accomplishment can now retrieve ranked historical records locally and explain why each record was surfaced.

## Recall ranking

The initial ranking policy is deliberately conservative:

1. **Explicit Work Graph relationship** — strongest signal.
2. **Shared evidence** — high-confidence bridge.
3. **Shared person, system, or project** — high-confidence contextual bridge.
4. **Shared tags and category** — supporting structured metadata.
5. **Time proximity** — supporting signal only.
6. **Shared record language** — bounded lexical similarity used only as a lower-confidence signal.

A high recall score means “inspect this record first.” It does **not** mean the records are causally related or that one proves the other.

## Related History

Incident and accomplishment editors now include a **Related History** tab.

For every retrieved record the UI shows:

- Record type and title.
- Record date.
- Recall score.
- Confidence class.
- Exact retrieval reasons.

The user can select high-confidence results, select all, or remove records before building an AI context bundle.

## Safe Apple Intelligence handoff

The Contextual Recall Engine does not silently send retrieved data to a model.

The workflow is:

1. WorkRecord ranks related history locally.
2. The user inspects the retrieved records and reasons.
3. The user explicitly selects records.
4. WorkRecord builds a bounded **AI Context Preview**.
5. The user inspects that preview.
6. Only an explicit **Analyze Selected Context** action submits the preview to Apple's on-device Foundation Models framework.

The resulting analysis is labeled non-evidentiary and is not automatically written into the incident, accomplishment, relationship graph, or evidence metadata.

## Context bounds

- Default recall result limit: 8 records.
- User-adjustable range: 3–20 records.
- Apple Intelligence context bundle: maximum 14,000 characters.
- Recall candidates are incidents and accomplishments; people, systems, projects, and evidence are used as graph bridge signals.
- Explicit graph links outrank inferred similarity.

## AI analysis guardrails

The contextual analysis prompt requires the model to:

- Treat retrieval scores as ranking metadata, not evidence.
- Keep direct support separate from plausible context.
- Avoid inferring motives or diagnosing people.
- Avoid converting correlation or time proximity into causation.
- State what the recalled history does not prove.
- Identify questions that still need verification.

## Compatibility

- No incident schema migration.
- No accomplishment schema migration.
- No Work Graph schema migration.
- Existing v1.5.0 Work Graph relationships are used automatically as recall signals.
- No recall result or AI analysis is persisted unless a future feature explicitly adds a user-controlled save workflow.

## Validation note

The new recall layer is source-compatible with the existing local-first architecture. A full AppKit/SwiftUI/FoundationModels build still requires Xcode and the macOS SDK on the target Mac before a signed binary is published.
