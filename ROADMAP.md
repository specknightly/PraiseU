# Entropy Shield WorkRecord Roadmap

WorkRecord is evolving from two complementary trackers into a local-first work intelligence system: one evidence-backed record of what went right, what went wrong, who and what were involved, how responsibilities changed, and where human judgment created value.

The roadmap is intentionally cumulative. Each release should leave the underlying record more useful to the next release without weakening the factual-integrity boundary.

## Product principles

- **Local first.** Core records, relationships, evidence metadata, and derived intelligence remain on the user's Mac.
- **Evidence before inference.** Facts, evidence, explicit relationships, hypotheses, and AI-generated analysis stay distinguishable.
- **No silent rewriting.** AI may suggest, summarize, retrieve, compare, and analyze, but it must not silently rewrite the user's factual record.
- **Traceability.** Future intelligence should be able to explain which records and evidence contributed to a conclusion.
- **Career utility.** Features should help a user defend the record when work is challenged and demonstrate value when seeking recognition or promotion.
- **AI-era framing.** Technical skill alone is easier to commoditize when AI can answer hard technical questions cheaply. WorkRecord should preserve evidence of judgment, ownership, context, reliability, prevention, coordination, impact, and organizational dependency.

## v1.5.0 — Relationship-Aware Work Graph

**Goal:** Connect incidents, accomplishments, evidence, people, systems, and projects without changing the source records.

Planned capabilities:

- Versioned local relationship database stored beside the existing incident and accomplishment databases.
- Typed graph nodes for incidents, accomplishments, evidence, people, systems, and projects.
- Explicit, user-created relationships with relationship type, note, timestamps, and stable IDs.
- Relationship browser available from the main application.
- Relationship tab inside incident and accomplishment editors.
- Quick creation of people, systems, and projects while linking a record.
- Derived evidence nodes resolved from existing evidence UUIDs and parent records.
- Safe deletion behavior: removing a relationship never deletes the underlying record or evidence.
- Relationship database backups and repository validation support.
- Foundation for future contextual recall and provenance.

**Definition of done:** A user can open any incident or accomplishment, link it to another record, evidence item, person, system, or project, save the relationship locally, and navigate those connections later.

## v1.6.0 — Contextual Recall Engine

**Status:** Implemented in v1.6.0.

**Goal:** Retrieve the right historical context automatically.

- Rank related graph nodes by explicit links, shared entities, systems, projects, time, tags, and semantic relevance.
- Show “Related history” beside the current record.
- Keep explicit relationships higher-confidence than inferred similarity.
- Allow recall results to be inspected before they are supplied to Apple Intelligence.
- Bound context size for predictable on-device performance.

## v1.7.0 — Prevention & Intervention Ledger

**Status:** Implemented in v1.7.0.

**Goal:** Quantify work that prevents future problems.

- Record preventive action, intervention type, risk avoided, recurrence avoided, and confidence.
- Link prevention accomplishments to the incidents or failure modes they address.
- Distinguish measured prevention from reasonable inference.
- Summarize avoided operational burden without inventing dollar values.

## v1.8.0 — Operational Burden Intelligence

**Status:** Implemented in v1.8.0.

**Goal:** Measure where time and cognitive load are actually going.

- Capture effort, interruption cost, after-hours work, escalation load, coordination load, and repeat-work burden.
- Aggregate burden by system, project, person/team context, and incident pattern.
- Separate recorded time from model-estimated burden.
- Highlight high-burden areas that produce little visible recognition.

## v1.9.0 — Responsibility Drift Observatory

**Status:** Implemented in v1.9.0.

**Goal:** Prove how the real job diverges from the job description.

- Compare work graph evidence to the user's role baseline.
- Track repeated out-of-role work, ownership expansion, and de facto responsibilities.
- Show drift over time rather than as a single AI opinion.
- Generate evidence-backed review material for scope, title, staffing, and compensation conversations.

## v2.0.0 — Work Intelligence Assistant

**Goal:** Conversational AI over the complete evidence graph.

- Local conversational interface backed by bounded graph retrieval.
- Answers cite the records, relationships, and evidence used.
- Separate factual answers from interpretations and hypotheses.
- Support questions about accomplishments, incidents, systems, projects, people, workload, and responsibility drift.

## v2.1.0 — Review Room

**Goal:** Turn the evidence graph into an interactive performance-review preparation system.

- Assemble promotion and review narratives from graph-backed evidence.
- Generate counterarguments and evidence-grounded responses.
- Practice likely management questions.
- Surface weak claims, missing proof, and contradictory records before the meeting.
- Maintain a clear boundary between source evidence and generated coaching.

## v2.2.0 — Evidence Provenance & Confidence

**Goal:** Make every AI conclusion traceable and defensible.

- Provenance objects linking generated claims to source records and evidence.
- Confidence labels based on source quality, explicit relationships, corroboration, and recency.
- Inspectable “why this conclusion?” views.
- Detect stale, missing, contradictory, or unverifiable evidence.
- Preserve hashes and evidence integrity metadata through downstream analysis.

## v2.3.0 — Anticipatory Intelligence

**Goal:** Detect patterns and surface useful context before the user asks.

- Surface related history while drafting a new incident or accomplishment.
- Detect recurring system, project, or workload patterns.
- Suggest relevant evidence to capture.
- Alert on emerging responsibility drift or repeated operational burden.
- Keep proactive suggestions explainable and dismissible.

## v2.4.0 — Adaptive Entropy Engine

**Goal:** Combine dynamic working memory, contextual recall, and application personality.

- Dynamic local working memory constrained by the evidence graph.
- Context assembly tuned to the task instead of one fixed prompt.
- Adjustable assistant personality and interaction style without changing factual standards.
- Learned local preferences for what the user considers important, while preserving provenance and user control.
- Policy layer defining what may be remembered, inferred, surfaced proactively, or excluded.

## Release discipline

Each version should include:

1. A release note describing behavior and data-model changes.
2. Schema compatibility notes.
3. Validation of every Swift source with the available parser/toolchain.
4. Explicit migration behavior for persisted data.
5. A Git commit history that keeps architecture, implementation, and release/version changes auditable.
