# Entropy Shield Memory OS — Product & Architecture Synthesis

## Why this exists

Entropy Shield should not be a collection of apps that merely store more information.

Its deeper purpose is to reduce the cognitive tax of **having to keep important context alive in human working memory**.

The system should make information dependable enough that a person can stop mentally rehearsing:

- what happened,
- why it mattered,
- who was involved,
- what they promised,
- how they solved it,
- what evidence exists,
- what remains unresolved,
- when they need to revisit it.

The desired psychological contract is:

> **I do not need to remember everything. I need to trust that the right information will come back with its context and provenance when I need it.**

## What WorkRecord already contributes to the Entropy Shield memory fabric

The currently connected Entropy Shield codebase exposes one application repository: WorkRecord. Within that application, several reusable memory primitives already exist.

### Capture / encoding

- Incident capture.
- Accomplishment capture.
- Quick Capture.
- Evidence Inbox.
- Optional Apple Mail evidence intake.
- Evidence hashes and metadata.

This answers: **“How do I get the memory out of my head and into a durable system?”**

### Association

- Relationship-Aware Work Graph.
- People, systems, projects, evidence, incidents, accomplishments.
- Explicit typed relationships.

This answers: **“What is this connected to?”**

### Recall

- Contextual Recall Engine.
- Bounded source packets.
- Inspectable retrieval reasons.
- Work Intelligence Assistant.

This answers: **“What prior context matters right now?”**

### Meaning

- Prevention & Intervention Ledger.
- Operational Burden Intelligence.
- Responsibility Drift Observatory.
- Accomplishment claim strength and work level.

This answers: **“Why did this matter?”**

### Trust

- Source citations.
- Evidence metadata.
- Measured vs estimated distinctions.
- Source-only Git privacy boundary.
- Local Apple Intelligence where supported.
- No silent rewriting of the factual record.

This answers: **“Can I rely on what the system is telling me?”**

These five capabilities should become shared Entropy Shield platform primitives rather than one-off WorkRecord features.

---

## The human-memory model

Entropy Shield should treat memory as multiple systems, not one search box.

### 1. Episodic

Memory of specific events.

Objects:
- incidents,
- accomplishments,
- decisions,
- meetings,
- changes,
- conversations.

Required properties:
- time,
- place/context,
- participants,
- source/evidence,
- what changed.

### 2. Semantic

Durable knowledge.

Objects:
- facts,
- systems,
- projects,
- roles,
- organizations,
- definitions,
- known dependencies.

Required properties:
- provenance,
- last verified,
- superseded-by,
- contradictions.

### 3. Procedural

Memory of how.

Objects:
- runbooks,
- troubleshooting flows,
- checklists,
- recurring workflows.

Required properties:
- prerequisites,
- steps,
- verification,
- rollback,
- exceptions,
- last successful use.

### 4. Prospective

Memory of the future.

Objects:
- commitments,
- reminders,
- waiting-for items,
- follow-ups,
- deadlines,
- recurring obligations.

Required properties:
- owner,
- trigger/date,
- linked context,
- completion evidence,
- status.

### 5. Working memory

Short-lived active context.

Objects:
- current task bundle,
- scratch notes,
- unresolved questions,
- recent sources,
- next actions.

Required properties:
- expiration,
- context budget,
- explicit promotion to durable memory.

### 6. Social / transactive

Memory distributed across people.

Objects:
- person/team context,
- expertise evidence,
- responsibilities,
- handoffs,
- commitments,
- stakeholder relationships.

Required properties:
- factual basis,
- sensitivity controls,
- no personality/motive inference.

### 7. Autobiographical

Memory of the user's own trajectory.

Objects:
- accomplishments,
- incidents,
- responsibilities,
- role baselines,
- learning,
- decisions,
- milestones.

Required properties:
- chronology,
- evidence,
- revision-safe history,
- narrative generation separated from fact.

### 8. Metamemory

Memory about memory.

Objects:
- confidence,
- provenance,
- contradictions,
- staleness,
- unknowns,
- missing evidence.

This is essential because the user needs to know not only **what the system remembers**, but **whether it should be trusted**.

---

## Safe forgetting model

Entropy Shield should not use “remember” and “delete” as the only states.

### Active

Eligible for proactive recall and immediate context assembly.

### Warm

Available through normal recall, but not constantly surfaced.

### Cold

Archived and searchable; excluded from proactive recall unless specifically relevant.

### Superseded

Preserved for history but marked as no longer current.

### Redacted

Record remains, but sensitive content is intentionally removed or hidden according to policy.

### Pending deletion

User has requested deletion; dependency impact is shown before execution.

### Permanently deleted

Source data is actually removed under explicit user control.

This model supports the central philosophy:

**Forgetting should usually mean reducing cognitive/access priority — not destroying evidence blindly.**

---

## The Entropy Engine

The “Entropy Engine” should become the shared policy and context layer.

Inputs:

- current task,
- people,
- systems/projects,
- recent events,
- open commitments,
- user memory policies,
- source freshness,
- retrieval history,
- explicit pinned/ignored status.

Outputs:

- bounded context bundle,
- proactive recall suggestions,
- stale-memory warnings,
- archive candidates,
- missing-evidence suggestions,
- relevant procedures,
- unresolved commitments.

The engine must always be able to answer:

- Why was this memory surfaced?
- Which source created it?
- Is it fact, classification, measurement, estimate, or inference?
- When was it last verified?
- What happens if I archive or delete it?

---

## What should be synthesized across Entropy Shield apps

Even when applications remain separate products, they should converge on:

- one memory object vocabulary,
- one provenance model,
- one relationship model,
- one retention/safe-forgetting model,
- one source-cited AI contract,
- one context-bundle format,
- one commitment model,
- one device-handoff model,
- one privacy policy language.

An application should be able to publish a **memory object** without handing over its entire database.

That prevents the Memory OS from becoming one giant undifferentiated data lake.

---

## The crown application

WorkRecord is a strong candidate to become the proving ground because career memory exercises nearly every difficult memory requirement at once:

- positive and negative events,
- evidence,
- people,
- systems,
- projects,
- future commitments,
- procedures,
- burden,
- responsibility,
- high-stakes recall,
- contradictory accounts,
- long time horizons,
- privacy,
- provenance,
- pressure.

If Entropy Shield can make it safe to forget workplace context without losing defensibility, the same architecture can support broader personal information-management applications.

The desired outcome is not a better note-taking app.

It is a **trusted external memory system**.


## Product specialization: Lumina and WorkRecord

The Entropy Shield ecosystem should not force every application to become a universal memory interface.

**Lumina** is the general-purpose notes/reminders and broad memory surface.

**WorkRecord** is the career-evidence specialization.

WorkRecord should reuse Entropy Shield memory principles only when they improve:

- promotion evidence,
- accomplishment defensibility,
- role/responsibility history,
- incident chronology,
- CYA documentation,
- evidence provenance,
- high-stakes recall.

Prospective reminders, general scratch notes, everyday personal knowledge, and broad second-brain behavior belong primarily in Lumina.

This specialization keeps the shared philosophy coherent without creating duplicate products.
