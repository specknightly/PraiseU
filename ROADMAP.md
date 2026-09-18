# Entropy Shield WorkRecord Roadmap

WorkRecord is evolving from a career evidence tracker into the first complete Entropy Shield memory application: a local-first system that helps a person **capture deliberately, retrieve intelligently, and forget safely**.

The long-term product principle is not “remember everything.” It is:

> **The human should not have to keep fragile context in working memory when Entropy Shield can preserve the right evidence, relationships, meaning, and future obligations locally — with enough provenance that the person can safely let go of the details.**

The roadmap is cumulative. Each release should make prior information easier to retrieve without weakening the distinction between source evidence, user classification, derived analysis, and AI-generated interpretation.

## Product principles

- **Local first.** Core records, relationships, evidence metadata, memory policy, and derived intelligence remain on the user's devices.
- **Human-controlled memory.** The system may retrieve, rank, compress, connect, and remind, but it must not silently redefine what happened or what matters.
- **Evidence before inference.** Facts, evidence, explicit relationships, estimates, hypotheses, and generated analysis stay distinguishable.
- **Source-cited intelligence.** An AI answer should be able to show what it relied on.
- **Safe forgetting.** Users should be able to move information out of active attention without losing the ability to recover it later.
- **Intentional deletion.** “Forget from active recall,” “archive,” “redact,” and “permanently delete” are different operations and must remain explicit.
- **Context over hoarding.** The goal is not maximum storage. The goal is minimum cognitive burden while preserving meaningful recall.
- **Temporal truth.** The system must preserve what was true at a particular time rather than overwriting history with the latest state.
- **Contradiction is information.** Conflicting records should be surfaced, not flattened into one confident answer.
- **Private by default.** AI should operate locally where platform capability permits, and runtime personal data must never enter the source repository.
- **Portable memory.** A person's memory system should survive application upgrades and eventually move safely across Entropy Shield applications and devices.
- **Career utility remains first-class.** WorkRecord must continue helping users defend factual work history and demonstrate value, responsibility, judgment, and impact.

---

## Human memory needs WorkRecord must ultimately cover

A mature Entropy Shield memory system should support all of the following human needs:

1. **Episodic memory — “What happened?”**
   - Events, chronology, incidents, accomplishments, conversations, decisions, and evidence.
2. **Semantic memory — “What is true or known?”**
   - People, systems, projects, facts, roles, definitions, dependencies, and durable knowledge.
3. **Procedural memory — “How did I do this?”**
   - Runbooks, troubleshooting steps, repeatable workflows, exceptions, and last-known-good procedures.
4. **Prospective memory — “What do I need to remember later?”**
   - Commitments, promises, follow-ups, deadlines, waiting-for items, and recurring obligations.
5. **Working memory — “What am I holding in my head right now?”**
   - Active task context, temporary bundles, unresolved questions, recent decisions, and short-lived scratch knowledge.
6. **Social / transactive memory — “Who knows what, owns what, or expects what?”**
   - Expertise, responsibility, handoffs, commitments, stakeholder context, and relationship history.
7. **Autobiographical / identity memory — “What have I done and how have I changed?”**
   - Career trajectory, accomplishments, incidents, responsibility expansion, decisions, learning, and personal evidence.
8. **Contextual recall — “What matters in this situation?”**
   - The right prior records when a person, project, system, place, task, or event appears again.
9. **Recognition and cueing — “Help me remember before I realize I forgot.”**
   - Explainable anticipatory context, reminders, and related-history prompts.
10. **Metamemory — “What do I know, how well do I know it, and what is missing?”**
    - Provenance, confidence, contradictory evidence, stale information, unknowns, and evidence gaps.
11. **Meaning and prioritization — “Why did this matter?”**
    - Impact, burden, prevention, risk, outcome, responsibility, and importance.
12. **Safe forgetting — “What can leave my attention now?”**
    - Archival tiers, supersession, compression, retention policy, redaction, and permanent deletion.
13. **Recall under pressure — “Can I recover this when I am stressed?”**
    - Review preparation, incident defense, concise evidence packets, timelines, and source-bound answers.
14. **Continuity — “Can my memory follow me between devices and Entropy Shield apps?”**
    - Portable schema, encrypted synchronization, conflict handling, and cross-application context handoff.

---

## Implemented foundation

### v1.5.0 — Relationship-Aware Work Graph

**Status:** Implemented.

Connect incidents, accomplishments, evidence, people, systems, and projects using explicit local relationships.

### v1.6.0 — Contextual Recall Engine

**Status:** Implemented.

Retrieve related history using explicit links, shared entities/evidence, time, tags, and record language while keeping retrieval reasons inspectable.

### v1.7.0 — Prevention & Intervention Ledger

**Status:** Implemented.

Preserve evidence of work whose value is defined by what did not happen.

### v1.8.0 — Operational Burden Intelligence

**Status:** Implemented.

Capture measured and estimated operational effort, interruptions, after-hours work, recovery time, cognitive load, and coordination load without turning workload into a competence score.

### v1.9.0 — Responsibility Drift Observatory

**Status:** Implemented.

Compare documented work with dated role baselines and show how responsibilities changed over time.

### v2.0.0 — Work Intelligence Assistant

**Status:** Implemented.

Conversational Apple Intelligence over a bounded, inspectable source packet. Users preview sources before model use, and generated answers cite the supplied local records.

---

# v2.1.0 — Review Room

**Human memory need:** Recall under pressure + autobiographical memory.

**Goal:** Make the evidence graph usable when the user must explain their work to another human under pressure.

Planned capabilities:

- Assemble review/promotion narratives from source-cited Work Intelligence packets.
- Build “show me the evidence” views for every generated claim.
- Generate skeptical counterarguments and evidence-grounded responses.
- Practice likely management questions without letting generated coaching become source evidence.
- Build neutral incident-defense timelines from selected records.
- Surface weak claims, missing proof, contradictions, and unsupported assumptions before a meeting.
- Create topic rooms such as promotion, performance review, role/title alignment, staffing, disputed incident, and handoff.
- Preserve a clean separation between:
  - factual record,
  - user interpretation,
  - assistant interpretation,
  - rehearsal/coaching text.
- Add a “pressure brief” mode: one-screen chronology, strongest evidence, important limitations, and unanswered questions.
- Allow a Review Room to be regenerated from the underlying sources instead of persisting stale AI prose as truth.

**Definition of done:** A user can enter a high-stakes work conversation with a concise, source-cited packet and can trace every factual statement back to local records.

---

# v2.2.0 — Evidence Provenance & Confidence

**Human memory need:** Metamemory — knowing what is known, how it is known, and what remains uncertain.

**Goal:** Make every important conclusion inspectable and defensible.

Planned capabilities:

- First-class provenance objects connecting a generated claim to:
  - source records,
  - evidence attachment metadata,
  - explicit graph relationships,
  - measurements,
  - estimates,
  - user classifications.
- Confidence labels based on source quality rather than model confidence.
- “Why do we think this?” inspector for AI conclusions.
- Contradiction detection:
  - conflicting dates,
  - different descriptions of the same event,
  - measured vs estimated disagreement,
  - stale role/system information,
  - superseded procedures.
- Evidence freshness / last-verified timestamps.
- Missing-evidence detection and capture suggestions.
- Hash/integrity continuity for attached evidence.
- Claim lineage through exports and Review Room packets.
- Explicit “insufficient evidence” states rather than forced conclusions.

**Definition of done:** A user can inspect a claim and see which records support it, which records weaken it, what is inferred, and what additional evidence would raise confidence.

---

# v2.3.0 — Anticipatory Intelligence

**Human memory need:** Recognition and cueing — remembering before the user notices the gap.

**Goal:** Surface useful context at the moment it becomes relevant without becoming noisy or intrusive.

Planned capabilities:

- Suggest related history while drafting a new incident or accomplishment.
- Surface previous work when a known person, system, project, ticket/reference, or recurring issue appears.
- Detect recurring operational burden or intervention patterns.
- Prompt for missing evidence when a record resembles a historically weak claim.
- Surface role-drift context when out-of-role work repeats.
- Explain every proactive suggestion: “shown because…”.
- Snooze, dismiss, mute, or permanently suppress a suggestion class.
- No unrequested rewriting of records.
- No personality, motive, mental-state, health, or competence inference.
- User-controlled sensitivity for proactive recall.

**Definition of done:** Entropy Shield can remind the user of relevant prior context at capture time, and every proactive memory can be dismissed or explained.

---

# v2.4.0 — Adaptive Entropy Engine

**Human memory need:** Working memory offload.

**Goal:** Let the user safely stop holding active context in their head.

Planned capabilities:

- Dynamic local working-memory bundles for the current task.
- Active-context stack:
  - current task,
  - current people,
  - current systems/projects,
  - unresolved questions,
  - recently used evidence.
- Memory tiers:
  - **Active** — frequently relevant, immediately retrievable.
  - **Warm** — available with contextual recall.
  - **Cold** — archived, searchable, excluded from proactive prompting.
- Automatic context condensation that retains links to source records.
- Importance signals based on explicit user actions and factual utility, not opaque model preference.
- Temporary scratch memory with user-defined expiration.
- Context budget management for on-device models.
- Explainable promotion/demotion between memory tiers.
- A policy layer controlling what may:
  - enter working memory,
  - be surfaced proactively,
  - be summarized,
  - be archived,
  - never be remembered.

**Definition of done:** A user can hand off a complex active thread to Entropy Shield, leave it alone, and later reconstruct the important context without keeping it mentally active.

---

# v2.5.0 — Prospective Memory & Commitment Ledger

**Human memory need:** Remembering the future.

**Goal:** Capture open loops so the user does not need to keep promises, follow-ups, and waiting-for items in working memory.

Planned capabilities:

- First-class commitments:
  - “I said I would…”
  - “They said they would…”
  - “Waiting for…”
  - “Follow up on…”
  - “Revisit after…”
- Due dates, review dates, recurrence, and contextual triggers.
- Link commitments to people, projects, systems, incidents, accomplishments, and evidence.
- Distinguish:
  - hard deadline,
  - soft follow-up,
  - dependency/waiting,
  - recurring obligation,
  - someday/maybe.
- Completion evidence and outcome notes.
- Local notification/reminder integration where supported.
- Commitment resurfacing when related context reappears.
- Detect orphaned commitments and unresolved loops.
- AI may extract **suggested** commitments from text, but creation always requires user approval.

**Definition of done:** A user can stop rehearsing “don’t forget to…” internally because open loops live in an inspectable commitment system.

---

# v2.6.0 — Procedural Memory & Runbooks

**Human memory need:** Remembering how.

**Goal:** Turn solved problems and repeated work into durable, verifiable procedures.

Planned capabilities:

- Create runbooks from incidents, accomplishments, prevention records, and user-authored procedures.
- Preserve:
  - prerequisites,
  - ordered steps,
  - verification step,
  - rollback/recovery,
  - exceptions,
  - environment/system,
  - last verified date.
- Link a procedure to the evidence that demonstrated it works.
- Distinguish a proven procedure from an AI-drafted suggestion.
- Detect stale procedures when related systems change.
- “How did I fix this last time?” conversational retrieval.
- Compare multiple successful approaches without silently merging incompatible steps.
- Capture troubleshooting branches and failed attempts as optional learning context.
- Promote repeatedly successful procedures into reusable templates.

**Definition of done:** A user can return months later and reconstruct not only what happened, but the verified method that worked.

---

# v2.7.0 — Social & Transactive Memory

**Human memory need:** Remembering people, responsibilities, expectations, and who knows what.

**Goal:** Preserve relationship context without turning the application into a personality-scoring system.

Planned capabilities:

- Person/team memory cards linked to factual interactions and work.
- Track:
  - explicit responsibilities,
  - expertise demonstrated in records,
  - commitments made,
  - handoffs,
  - recurring collaboration context,
  - systems/projects associated with the person.
- “Who knows about this?” and “Who was involved last time?” retrieval.
- Handoff packages showing open commitments, relevant systems, procedures, and recent context.
- Explicit distinction between:
  - documented responsibility,
  - repeated association,
  - inferred expertise.
- Never infer personality, loyalty, motive, competence, or mental state.
- Sensitive-note controls so private observations can be excluded from AI/context retrieval.
- Contact/context deduplication and alias handling.

**Definition of done:** A user can stop maintaining fragile mental models of “who knows what” while preserving only defensible, relevant relationship context.

---

# v2.8.0 — Memory Hygiene & Safe Forgetting

**Human memory need:** Forgetting without fear.

**Goal:** Make forgetting a deliberate information-management operation rather than either permanent hoarding or accidental loss.

Planned capabilities:

- Memory lifecycle states:
  - Active,
  - Warm,
  - Cold archive,
  - Superseded,
  - Redacted,
  - Pending deletion,
  - Permanently deleted.
- Separate **forget from proactive recall** from **delete the source**.
- Deduplicate overlapping records while preserving provenance.
- Mark facts/procedures as superseded without rewriting history.
- Retention policies by record class.
- “Why am I still keeping this?” storage audit.
- Stale-context review.
- Safe deletion preview showing:
  - links that will break,
  - claims that lose support,
  - exports/reports affected.
- User-confirmed permanent deletion.
- Redaction tools for sensitive content.
- Archive compression/summary objects that always retain links to original sources until originals are explicitly deleted.
- Memory-policy dashboard showing what AI is allowed to retrieve.

**Definition of done:** A user can reduce cognitive and storage clutter confidently because Entropy Shield makes the consequences of forgetting visible before anything is destroyed.

---

# v2.9.0 — Pocket Continuity & Memory Handoff

**Human memory need:** Continuity between places and devices.

**Goal:** Make capture and recall available wherever the memory occurs while preserving local-first control.

Planned capabilities:

- A mobile-first capture surface for:
  - quick text,
  - voice note,
  - photo/document evidence,
  - commitment,
  - incident,
  - accomplishment,
  - “remember this for later.”
- One-tap  capture must always present a deterministic capture sheet; it must never be a decorative/dead control.
- Share-sheet ingestion from Mail, Files, Photos, Safari, and other supported apps.
- Offline capture queue.
- Explicit sync status and conflict resolution.
- Encrypted device-to-device / user-controlled sync architecture.
- Cross-device continuity for:
  - active context,
  - commitments,
  - memory tiers,
  - source IDs,
  - graph relationships.
- Never place runtime personal data into GitHub/source control.
- “Send context to Mac” / “continue here” handoff.
- Mobile quick recall: “What was I supposed to remember about this person/project/system?”

**Definition of done:** A memory captured on mobile becomes reliably available to the desktop memory system without requiring the user to remember to move it manually.

---

# v3.0.0 — Entropy Shield Memory OS

**Human memory need:** A trusted external memory layer across life/work applications.

**Goal:** Turn the accumulated WorkRecord architecture into a reusable Entropy Shield memory fabric: a local, policy-governed system that remembers context so the human can safely stop carrying it.

## Core memory primitives

Every Entropy Shield application should be able to speak the same local memory language:

- **Event** — something that happened.
- **Fact / Claim** — something believed or asserted, with provenance.
- **Entity** — person, system, project, place, organization, object.
- **Evidence** — attachment or source that supports a claim.
- **Relationship** — explicit connection between memory objects.
- **Procedure** — how to do something.
- **Commitment** — something that must happen later.
- **Decision** — choice, rationale, alternatives, and outcome.
- **Question / Unknown** — something unresolved.
- **Context Bundle** — bounded working-memory packet for a task.
- **Summary** — compressed derived memory with links to its sources.
- **Policy** — what may be remembered, surfaced, shared, archived, or deleted.

## Memory fabric

- Shared IDs and provenance across Entropy Shield apps.
- App-specific stores remain independent where useful, but publish approved memory objects into the local fabric.
- Cross-app query:
  - “What do I know about this?”
  - “Why do I know it?”
  - “What happened last time?”
  - “What am I waiting on?”
  - “How did I solve this?”
  - “Who should I involve?”
  - “What changed?”
  - “What can I safely forget?”
- Local semantic + graph retrieval.
- Temporal reasoning that preserves historical state.
- Contradiction-aware recall.
- Bounded local AI context assembled from inspectable source objects.
- Universal provenance and source citation.
- User-controlled proactive recall.
- Memory lifecycle/retention engine.
- Portable encrypted backup/export.
- Device handoff and continuity.
- A global “What is Entropy Shield remembering for me?” inspector.

## The v3.0 promise

The crown behavior should be simple to explain:

> **Capture it once. Keep the evidence. Preserve the context. Let Entropy Shield decide when it is relevant — under rules you can inspect — so you do not have to keep rehearsing it in your head.**

The system should make it safe to say:

> **“I can forget this for now. Entropy Shield will help me recover it when it matters.”**

That is the completion criterion for v3.0.

---

## Cross-application architecture requirements

These requirements should become shared conventions for every Entropy Shield application:

1. Stable UUID-based memory objects.
2. Typed relationships.
3. Source provenance.
4. Local-first persistence.
5. Explicit memory policies.
6. No silent AI mutation of source evidence.
7. AI outputs stored separately from source facts.
8. Temporal/version-aware state.
9. Inspectable retrieval reasons.
10. Memory lifecycle states.
11. User-controlled deletion.
12. Portable, documented schemas.
13. Source-only Git repositories.
14. Mobile/desktop continuity without source-control leakage.
15. Privacy-preserving local intelligence wherever platform support allows.

---

## Release discipline

Each version should include:

1. A release note describing behavior and data-model changes.
2. Schema compatibility notes.
3. Validation of every Swift source with the available parser/toolchain.
4. Explicit migration behavior for persisted data.
5. A Git commit history that keeps architecture, implementation, and release/version changes auditable.
6. A source-only privacy audit.
7. A “memory safety” review covering:
   - provenance,
   - contradiction behavior,
   - deletion/retention behavior,
   - proactive recall boundaries,
   - what the AI is and is not permitted to remember.
