# Data Privacy Boundary

Entropy Shield WorkRecord is a source-code repository. It must not contain a user's live career record.

## Never commit runtime data

The following data belongs only in the user's selected local WorkRecord repository and is excluded from Git:

- Incident records.
- Accomplishment records.
- Evidence attachments.
- Evidence Inbox contents.
- Database backups.
- Work Graph relationship data.
- Prevention & Intervention Ledger data.
- Operational Burden records.
- Responsibility Drift role-baseline snapshots.
- Imported email evidence or exported workplace documents.

The application stores live data under the user-selected WorkRecord repository, which defaults to the user's Application Support directory. That runtime repository is not the Git source repository.

## Repository rule

GitHub should contain only application source code, documentation, release metadata, and static application assets.

Do not add sample career records derived from a real user. Test fixtures, if introduced later, must be synthetic and clearly labeled as such.

## Current audit

Before v1.8.0 development, the reachable `main` history was audited for runtime database paths, evidence directories, and common evidence/document file formats. No live WorkRecord database or evidence attachment was found.

Additional safeguards added for v1.8.0 and extended for v1.9.0:

- Runtime WorkRecord paths and common evidence attachment formats are ignored by Git.
- The application refuses to create or link its live database inside any Git working tree.
- Responsibility Drift baseline snapshots are treated as runtime career data and excluded from source control.
- `Scripts/verify-source-only.sh` checks tracked paths, including the Responsibility Drift database.
- GitHub Actions runs that privacy guard on pushes and pull requests.

If runtime data is ever discovered in Git history, stop normal development and treat removal as a privacy incident rather than simply deleting the file in a later commit.


## Work Intelligence Assistant

v2.0.0 does not add a conversational database.

- Assistant conversation history is held in memory while the assistant window is open.
- The model receives only the user-approved bounded source packet for the current question.
- Prior turns are conversation context, not evidence.
- Evidence attachment contents are not automatically read by the assistant; only recorded metadata/context already present in WorkRecord can be supplied.
- Transcript export requires an explicit user action.
- Transcript export is refused when the destination is inside a Git working tree.
- Source packaging uses Git-tracked files only and runs the source-only privacy guard before producing an artifact.
