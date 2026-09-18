# Build Fix v1.3.1

This maintenance release fixes the macOS 27 / Swift 6 build failures reported against v1.3.0.

## Fixes

- Added the `reviewPrep`, `insights`, and `intake` cases to the Accomplishment list title switch.
- Added `insights` and `intake` handling to AccomplishmentStore filtering. These utility selections intentionally expose the full accomplishment set when a list is requested.
- Changed the Vision import to `@preconcurrency import Vision`.
- Reworked OCR execution so `VNRecognizeTextRequest` is created inside the background closure instead of being captured by a `@Sendable` closure.
- Re-ran Swift frontend parse validation over every Swift source file.

No data schema changes are made in this release. Existing incident and accomplishment records remain compatible.
