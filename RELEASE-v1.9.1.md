# Entropy Shield WorkRecord v1.9.1

## Modern Dark / Matte-Gold Theme

v1.9.1 is a visual-system refresh. It does not change the WorkRecord data model, evidence model, or local-storage behavior.

The design direction is dark-only: layered near-black/charcoal surfaces with restrained pale matte-gold emphasis.

## Palette

The previous dark navy and bright-blue accent system has been replaced by:

- Near-black application canvas.
- Charcoal sidebar and panel surfaces.
- Slightly raised neutral card surfaces.
- Warm pale/matte gold as the primary accent family.
- Low-opacity gold borders for separation.
- Warm off-white primary text.
- Neutral gray secondary text.
- Existing red reserved for destructive/error semantics.

There is no green primary accent.

## Dark mode only

The app now explicitly uses macOS Dark Aqua appearance.

Dark appearance is applied to:

- Main WorkRecord window.
- Settings.
- Menu-bar Quick Capture content.
- Native SwiftUI controls through the root tint/appearance.

The application no longer follows a light system appearance for its core windows.

## Navigation and selection

The main mode switch keeps the explicit Incidents / Accomplishments controls introduced in v1.9.0.

v1.9.1 styles the selected mode with a matte-gold surface and dark foreground text.

Incident and accomplishment sidebars now use:

- Gold text/icons for the active destination.
- A low-opacity gold selection surface.
- A subtle gold border.
- Softer neutral count badges.

This removes the previous solid-blue selection blocks.

## Record cards

Selected incident and accomplishment cards now use a dark gold-tinted selection surface rather than a bright accent fill.

Metadata, evidence counts, pills, and icons retain strong contrast without turning the full card gold.

## Editors

Selected editor tabs now use pale gold text and underline treatment.

Primary actions continue to use the matte-gold tint family.

Panel cards use:

- Slight top-left to bottom-right neutral gradient.
- Low-contrast gold border.
- Restrained soft shadow.
- Increased continuous corner radius.

## Logo mark

The fallback Entropy Shield mark now uses warm off-white for its outer geometry and pale gold for the internal mark, matching the new theme.

## Privacy

The visual reference supplied for this redesign is not committed to GitHub.

No incident data, accomplishment data, evidence attachment, role baseline, Work Graph database, Prevention Ledger database, or Operational Burden database is part of this release source tree.

## Compatibility

- No incident schema change.
- No accomplishment schema change.
- No Work Graph schema change.
- No Prevention Ledger schema change.
- No Operational Burden schema change.
- No Responsibility Drift schema change.
- No migration is required.

## Validation note

The release was reviewed for central theme usage, main navigation selection states, record list selection states, editor tab states, forced dark appearance, version metadata, and the source-only privacy boundary.

A final pixel-level visual check and complete AppKit/SwiftUI build still requires Xcode and the target macOS SDK on a Mac.
