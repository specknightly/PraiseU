# Entropy Shield WorkRecord v1.9.0

## Responsibility Drift Observatory

v1.9.0 turns scope drift from a vague career complaint into a dated, inspectable evidence model.

It also fixes the main Mode switch regression: the macOS segmented picker has been replaced by explicit Incidents and Accomplishments buttons that directly change application mode and repair the active record selection.

## Mode-switch fix

The previous segmented Picker could fail to change the visible tracker mode.

v1.9.0 replaces it with two explicit controls:

- Incidents
- Accomplishments

Each button directly updates the mode state, clears cross-mode search text, and repairs the relevant selection.

## Versioned role baselines

Role scope can change over time. A single editable text field is not enough to make historical comparisons defensible.

WorkRecord can now save dated role-baseline snapshots containing:

- Official role title.
- Role definition / assigned responsibilities.
- Expected adjacent or out-of-role work percentage.
- Effective date.
- Notes and timestamps.

The Observatory uses the baseline effective for a period when one exists.

If no dated snapshot has been saved, it uses the current Settings values only as a fallback and visibly labels that baseline as **current Settings / unsnapshotted**.

## Explicit scope classification

Scope classification now spans four record types:

- Accomplishments.
- Incidents.
- Prevention / intervention records.
- Operational burden records.

Records can be classified as:

- Core Role.
- Other / Scope Drift.
- Unclassified.

Unclassified records are excluded from the scope percentage instead of being silently treated as core or out-of-role.

## Evidence-mix timeline

The Observatory groups dated work evidence by month and displays:

- Core-role record count.
- Other / scope-drift record count.
- Unclassified record count.
- Other-scope percentage of classified records.
- Configured expected adjacent-work allowance for the applicable baseline.
- Difference in percentage points.
- Measured out-of-role burden time.
- Estimated out-of-role burden time.

The percentage is deliberately labeled **evidence mix, not time share**. Record counts do not prove how working hours were allocated.

## Out-of-role burden

Measured and estimated operational burden remain separate.

The Observatory totals only burden records explicitly classified as Other / Scope Drift and reports:

- Measured out-of-role burden.
- Estimated out-of-role burden.

No inferred conversion to compensation, dollars, or percentage of the workweek is performed.

## Higher-level out-of-role work

Accomplishments already include work-level classification.

v1.9.0 separately surfaces Other / Scope Drift accomplishments classified as:

- Advanced.
- Specialist.
- Project Owner.
- Strategic / Leadership.

This prevents a large number of routine records from being presented as stronger promotion evidence than a smaller number of higher-responsibility records.

## De facto ownership signals

The Observatory uses explicit Work Graph links plus prevention/burden links to identify systems and projects repeatedly associated with out-of-role records.

For each signal it can show:

- System or project.
- Number of supporting out-of-role records.
- Evidence source types.
- First and most recent supporting dates.
- Measured and estimated burden associated with those records.

These are **ownership signals**, not proof of formal accountability. The application says so directly.

## Evidence-backed review packet

The Observatory can export a local Markdown evidence packet containing:

- Role baseline.
- Classified evidence counts.
- Evidence-mix comparison to the configured allowance.
- Measured and estimated out-of-role burden.
- Higher-level out-of-role accomplishments.
- Repeated system/project ownership signals.
- Recent out-of-role evidence.
- Suggested factual uses for role/title, staffing, compensation, promotion, and reclassification discussions.
- Explicit limitations and evidence gaps.

The packet is generated locally from the user's data and is not stored in GitHub.

## Responsibility Drift review brief

Apple Intelligence can generate an on-device review brief from the deterministic evidence packet.

The prompt requires the model to:

- Avoid inventing duties or organizational policy.
- Avoid inventing compensation bands or peer performance.
- Avoid inferring manager/coworker motives.
- Treat scope labels as user classifications requiring corroboration.
- Treat record percentages as evidence mix, not working-time measurement.
- Keep measured and estimated burden separate.
- Treat repeated system/project linkage as an ownership signal, not proof of official responsibility.
- Avoid recommending a specific salary or compensation outcome.
- Identify skeptical counterarguments and missing evidence.

The generated brief is non-evidentiary.

## Local storage and privacy

Responsibility Drift baseline history is stored locally at:

`ResponsibilityDrift/responsibility-drift.json`

with rolling backups under:

`ResponsibilityDrift/Backups/`

Both paths are excluded by `.gitignore` and checked by the GitHub source-only privacy guard.

No runtime Responsibility Drift data is included in the Git source repository.

## Compatibility

- Existing accomplishment records keep their existing scope field.
- Incidents, prevention records, and operational-burden records gain an optional scope field. Missing fields decode as unclassified, preserving compatibility with older local data.
- No Work Graph schema migration.
- No evidence-file migration.
- No change to the local-only data boundary.

## Validation note

The branch was reviewed for mode-switch state flow, backward-compatible optional scope fields, dated baseline persistence, deterministic drift calculations, ownership-signal construction, export limitations, AI guardrails, and source-only privacy paths.

A final AppKit/SwiftUI/FoundationModels compile and signed application test still requires Xcode and the target macOS SDK on a Mac.
