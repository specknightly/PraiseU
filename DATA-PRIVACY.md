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
- Imported email evidence or exported workplace documents.

The application stores live data under the user-selected WorkRecord repository, which defaults to the user's Application Support directory. That runtime repository is not the Git source repository.

## Repository rule

GitHub should contain only application source code, documentation, release metadata, and static application assets.

Do not add sample career records derived from a real user. Test fixtures, if introduced later, must be synthetic and clearly labeled as such.

## Current audit

Before v1.8.0 development, the reachable `main` history was audited for runtime database paths, evidence directories, and common evidence/document file formats. No live WorkRecord database or evidence attachment was found.

If runtime data is ever discovered in Git history, stop normal development and treat removal as a privacy incident rather than simply deleting the file in a later commit.
