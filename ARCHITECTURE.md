# Architecture Notes

## Design inversion from Accomplishment Tracker

The Accomplishment Tracker asks: **What did I accomplish, what value did it create, and what proves it?**

Incident Tracker asks: **What happened, what was the impact, how did I respond, what proves the record, and what remains unresolved?**

The shared architecture is deliberate:

| Accomplishment concept | Incident Tracker equivalent |
|---|---|
| Situation / context | Observed facts + context / interpretation |
| What I did | Response / what I did |
| Outcome | Resolution / outcome |
| Organizational impact | Incident impact |
| Evidence | Evidence with SHA-256 integrity metadata |
| Human Value AI | Incident AI + human-judgment analysis |
| Review packet | Incident packet / review packet |
| Categories / tags | Categories / tags |
| Pinned | Pinned |
| Calendar/history | Incident timeline |

## Factual-integrity boundary

The application deliberately keeps these concepts separate:

1. **Observed facts**: directly observed, reported, logged, or otherwise known information.
2. **Context / interpretation**: hypotheses, explanations, statements from others, or contextual framing.
3. **Impact**: what actually changed or was disrupted.
4. **Response**: actions taken by the user or others in response.
5. **Resolution**: the resulting state.
6. **Follow-up**: the unresolved dependency or next action.
7. **Evidence**: source files kept independently from the prose narrative.
8. **AI analysis**: explicitly non-evidentiary derivative interpretation.

This prevents AI output, frustration, or hindsight from being silently blended into the original event record.

## Storage boundary

`IncidentStore` is the single persistence boundary. Views never decide where evidence lives and do not write database files directly.

Incident records are stored in a versioned `IncidentDatabase` envelope. The loader can also read the earliest unwrapped-array prototype format so the schema can evolve without casually setting fire to the user's history.

## Evidence boundary

Import flow:

1. User selects one or more source files with `NSOpenPanel`.
2. The source bytes are read.
3. SHA-256 is calculated from those bytes.
4. A copied file is written into the incident's evidence directory.
5. The record stores the original name, copied filename, byte count, import time, hash, and note.
6. Verification recalculates the hash from the current copied file.

## AI boundary

`LocalAIService` uses `SystemLanguageModel.default` through Apple's Foundation Models framework when available.

The service has two intentionally narrow operations:

- `analyze(_:)`: derivative analysis only.
- `neutralizeFacts(_:)`: proposed factual rewrite only.

No AI function writes directly to persistent storage. The user must explicitly save the incident, and the neutral rewrite requires a separate Apply action before it replaces the facts field.

## Export boundary

`ExportService` generates static self-contained HTML. Images are embedded as data URIs. Other evidence types are embedded as downloadable/openable data links. The original file name, import timestamp, SHA-256, and current verification result accompany every attachment.
