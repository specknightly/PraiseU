# Entropy Shield WorkRecord Roadmap

WorkRecord is **not** the general-purpose Entropy Shield notes/reminders application.

**Lumina owns general notes, reminders, everyday capture, and broad personal memory.**

**WorkRecord owns career evidence.**

Its two primary jobs are:

1. **Promotion evidence** — preserve wins, impact, judgment, responsibility, prevention, measurable burden, and evidence strong enough to support a review, raise, promotion, title change, or reclassification discussion.
2. **CYA incident documentation** — preserve uncomfortable workplace events while the facts are fresh, with chronology, corroboration, references, evidence, response, outcome, and explicit separation between fact and interpretation.

Everything added after v2.0 must strengthen one or both of those jobs.

The Entropy Shield philosophy still applies: people should not have to remember every detail. The application should preserve the right context, evidence, provenance, and relationships so the user can safely stop rehearsing career events in working memory and recover them when the stakes are high.

---

## Product rules

- **Evidence beats volume.** Ten vague accomplishments are less useful than two well-supported accomplishments with clear impact.
- **Facts beat rhetoric.** Incident records must prioritize observed facts, chronology, references, corroboration, and attached evidence.
- **AI organizes; it does not manufacture.** Generated analysis remains separate from the factual record.
- **Promotion claims must be traceable.** Every significant career-value claim should be inspectable back to records and evidence.
- **CYA does not mean accusation.** The app records what happened, what was observed, what was done, and what evidence exists. It should not infer motive or personality.
- **Measured, estimated, and inferred stay distinct.**
- **Local first.** Sensitive work records and evidence stay under user control.
- **Source-only GitHub.** Runtime career data and attachments never belong in the source repository.
- **Useful under pressure.** The application should make high-stakes review or incident recall easier, not force the user to reconstruct history manually.

---

## Implemented foundation

### v1.5.0 — Relationship-Aware Work Graph
**Status:** Implemented.

Connect incidents, accomplishments, evidence, people, systems, and projects.

### v1.6.0 — Contextual Recall Engine
**Status:** Implemented.

Retrieve relevant historical context with explainable ranking.

### v1.7.0 — Prevention & Intervention Ledger
**Status:** Implemented.

Capture preventive work whose value is often invisible because failure never occurred.

### v1.8.0 — Operational Burden Intelligence
**Status:** Implemented.

Measure where operational time and attention are going while preserving measured/estimated distinctions.

### v1.9.0 — Responsibility Drift Observatory
**Status:** Implemented.

Show how documented responsibilities diverge from the written role over time.

### v2.0.0 — Work Intelligence Assistant
**Status:** Implemented.

Conversational, source-cited local analysis over the complete WorkRecord evidence system.

### v2.0.1 — Career Evidence Focus
**Status:** In progress.

Re-center WorkRecord around **Record the Win / Document the Incident**.

- Quick Capture supports both wins and incidents.
- Main creation actions use promotion/CYA language.
- Product copy explicitly positions WorkRecord as a career evidence vault.
- Lumina remains the general notes/reminders product.

---

# v2.1.0 — Review Room

**Primary job:** Promotion evidence + high-stakes recall.

**Goal:** Turn the evidence already in WorkRecord into an interactive preparation room for reviews, promotion meetings, title discussions, and disputed incidents.

Planned capabilities:

- Create a Review Room from selected accomplishments/incidents.
- Promotion-room mode:
  - strongest accomplishments,
  - measurable impact,
  - higher-level work,
  - responsibility drift,
  - prevention value,
  - burden absorbed,
  - evidence strength.
- Incident-defense mode:
  - chronology,
  - observed facts,
  - response,
  - references,
  - evidence,
  - corroboration,
  - unresolved questions.
- “Challenge my case” adversarial preparation.
- Source-cited talking points.
- Missing-evidence checklist before the meeting.
- One-screen pressure brief.
- Generated rehearsal text remains non-evidentiary.

**Definition of done:** The user can walk into a review or uncomfortable meeting with a concise, source-backed case instead of relying on memory.

---

# v2.2.0 — Evidence Provenance & Confidence

**Primary job:** Hard evidence.

**Goal:** Make every promotion claim and incident conclusion defensible.

Planned capabilities:

- First-class claim-to-source lineage.
- Evidence strength based on source quality, not model confidence.
- “Why do we believe this?” inspector.
- Hash verification status surfaced next to claims using attachments.
- Last-verified timestamps.
- Contradiction detection:
  - dates,
  - reference numbers,
  - conflicting descriptions,
  - measured vs estimated values,
  - outdated role information.
- Unsupported-claim warnings.
- Missing-proof suggestions.
- Exportable evidence manifest.
- Explicit insufficient-evidence state.

**Definition of done:** Any important claim can be traced to the records and attachments that support or weaken it.

---

# v2.3.0 — Promotion Case Builder

**Primary job:** Turn wins into promotion-grade evidence.

**Goal:** Convert accomplishments into a durable, cumulative promotion case rather than a last-minute brag document.

Planned capabilities:

- Promotion evidence dashboard:
  - business/operational impact,
  - work level,
  - role scope,
  - responsibility duration,
  - claim strength,
  - supporting evidence count.
- STAR/CAR-style evidence stories generated only from source fields.
- “Why this matters at the next level” analysis.
- Separate:
  - routine excellence,
  - advanced technical work,
  - specialist work,
  - project ownership,
  - strategic/leadership work.
- Track repeated higher-level behavior across time.
- Detect weak accomplishment records before review season.
- Suggest evidence to attach:
  - ticket,
  - email,
  - screenshot,
  - metric,
  - change record,
  - stakeholder acknowledgment.
- Build manager-ready promotion packet.
- Never invent compensation ranges or organizational promotion criteria.

**Definition of done:** The user can produce a promotion packet whose major claims are backed by durable local evidence.

---

# v2.4.0 — Incident Defense Room

**Primary job:** Detailed CYA documentation.

**Goal:** Make uncomfortable incidents extremely easy to document accurately while details are fresh.

Planned capabilities:

- Guided incident capture:
  - what happened,
  - when,
  - when discovered/recorded,
  - who was present,
  - system/location,
  - exact observed facts,
  - exact statements when remembered,
  - references,
  - actions taken,
  - impact,
  - resolution,
  - follow-up.
- Explicit **fact / interpretation / unanswered question** separation.
- Chronology builder.
- Witness/corroboration field improvements.
- “What evidence should I preserve now?” checklist.
- Neutral-language reviewer that never replaces facts automatically.
- Incident completeness score focused on defensibility.
- Missing reference/witness/evidence warnings.
- “What could reasonably be challenged?” analysis.
- Export a neutral CYA fact packet.
- Never infer intent, motive, dishonesty, hostility, or mental state.

**Definition of done:** A user can reconstruct an uncomfortable event later without depending on stressed or fading memory.

---

# v2.5.0 — Evidence Intake & Corroboration

**Primary job:** Strengthen promotion and CYA records with receipts.

**Goal:** Reduce the friction between “I know there was an email/ticket/screenshot” and having that evidence linked to the correct record.

Planned capabilities:

- Smarter Evidence Inbox triage.
- Suggested parent record matching with user confirmation.
- OCR/text extraction as **searchable supporting context**, never automatic fact.
- Email/ticket/reference extraction.
- Duplicate evidence detection by hash.
- Attachment provenance:
  - original name,
  - import time,
  - source path/context where available,
  - hash,
  - linked record,
  - note.
- Corroboration suggestions across multiple sources.
- Evidence gap prompts for strong promotion claims.
- Evidence-preservation prompts for open incidents.
- Bulk evidence review.

**Definition of done:** Important wins and incidents are not left as unsupported prose when relevant source material exists.

---

# v2.6.0 — Career Trajectory Observatory

**Primary job:** Prove sustained growth rather than isolated wins.

**Goal:** Show how responsibility, judgment, and work level changed across months/years.

Planned capabilities:

- Career timeline combining:
  - accomplishments,
  - responsibility drift,
  - prevention,
  - burden,
  - project/system ownership signals.
- Repeated higher-level-work detection.
- First-seen / sustained-since signals.
- Responsibility expansion by project/system.
- Promotion-readiness evidence matrix.
- “One-time stretch” vs “sustained responsibility” distinction.
- Role-baseline comparison over time.
- Evidence-backed growth narrative.
- Gaps where the user has strong activity but weak proof.

**Definition of done:** The user can show a sustained pattern of operating above the written role without relying on anecdote.

---

# v2.7.0 — Incident Pattern & Response Intelligence

**Primary job:** Defend against distorted narratives while learning from recurring problems.

**Goal:** Find repeated incident patterns without turning correlation into blame.

Planned capabilities:

- Repeated system/category/reference patterns.
- Similar chronology clusters.
- Recurring escalation/follow-up gaps.
- Response consistency analysis.
- Prevention records linked to prior incidents.
- “Same failure, different date” retrieval.
- Distinguish:
  - repeated environment/system issue,
  - repeated process gap,
  - repeated ownership ambiguity,
  - repeated user action.
- No motive/personality scoring.
- No automatic fault assignment.
- Source-cited pattern summaries.

**Definition of done:** A user can show that an incident fits—or does not fit—a documented historical pattern.

---

# v2.8.0 — Career Evidence Integrity & Retention

**Primary job:** Preserve the record without creating uncontrolled data hoarding.

**Goal:** Keep evidence trustworthy, portable, and intentionally retained.

Planned capabilities:

- Evidence integrity dashboard.
- Broken/missing-file detection.
- Hash re-verification.
- Export manifests.
- Archive closed incidents.
- Archive old accomplishments while keeping promotion-history access.
- Redaction workflow for sensitive exports.
- Safe deletion preview showing which claims/relationships lose support.
- Retention policy by record type.
- Encrypted backup/export options where supported.
- Explicit distinction between:
  - archive,
  - exclude from AI recall,
  - redact,
  - delete.

**Definition of done:** The user can trust the long-term record and intentionally reduce clutter without accidentally destroying important proof.

---

# v2.9.0 — Career Packet Studio

**Primary job:** Produce the right artifact for the audience.

**Goal:** Turn the same underlying evidence into audience-specific, source-grounded packets.

Planned packet types:

- Annual performance review.
- Promotion/title-change case.
- New-manager handoff.
- Project impact packet.
- Responsibility-drift packet.
- Incident fact packet.
- HR/management chronology packet.
- Personal private “full record” packet.

Controls:

- Choose included records/evidence.
- Redact names/fields for export.
- Include/exclude AI interpretation.
- Include evidence manifest.
- Show claim-to-source references.
- Neutral vs advocacy tone.
- Export HTML/Markdown/PDF where supported.

**Definition of done:** The user can produce a professional artifact without rewriting the same history from scratch every time.

---

# v3.0.0 — Entropy Shield Career Evidence OS

**Primary job:** Become the trusted external memory for a career.

**Goal:** Make WorkRecord the place where a professional can safely stop carrying career history in their head because both the positive and defensive record are preserved.

## Two permanent ledgers

### The Win Ledger

Preserves:

- accomplishments,
- impact,
- metrics,
- evidence,
- responsibility level,
- prevention,
- project ownership,
- role drift,
- sustained higher-level behavior.

Primary question:

> **What evidence proves the value I created and the level at which I actually operated?**

### The Incident Ledger

Preserves:

- observed facts,
- chronology,
- people/witnesses,
- references,
- response,
- impact,
- resolution,
- follow-up,
- attached evidence,
- related history.

Primary question:

> **If this event is questioned later, what contemporaneous factual record can I produce?**

## Shared intelligence

Both ledgers use the same:

- Work Graph,
- Contextual Recall,
- source-cited Work Intelligence,
- provenance/confidence model,
- evidence store,
- role baseline,
- timeline,
- export system,
- local-first privacy rules.

## v3.0 promise

The user should be able to say:

> **“I do not need to remember every win or every uncomfortable incident. I recorded it when it happened, kept the receipts, and WorkRecord can reconstruct the defensible career story when I need it.”**

That is the completion criterion for v3.0.

---

## Relationship to Lumina

**Lumina:** general notes, reminders, everyday memory, future obligations, broad personal knowledge.

**WorkRecord:** professional wins, career-value evidence, uncomfortable incidents, CYA documentation, review/promotion preparation.

The applications may eventually share Entropy Shield design and memory primitives, but they should not collapse into the same product.

WorkRecord stays relevant by being **narrower and more defensible**, not by becoming a general notes app.

---

## Release discipline

Every release should include:

1. Release notes.
2. Schema compatibility/migration notes.
3. Swift parser/build validation.
4. Source-only privacy audit.
5. Evidence-safety review.
6. AI claim-boundary review.
7. Promotion/CYA usefulness check:
   - Does this release make a win easier to prove?
   - Does this release make an uncomfortable incident easier to reconstruct factually?
   - If neither, reconsider whether the feature belongs in WorkRecord.
