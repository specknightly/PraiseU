# Contributing

This repository is currently maintained as a focused macOS application rather than a broad framework.

Before submitting changes:

1. Keep Accomplishment Tracker usable as a standalone application.
2. Preserve the historical `WorkEvidence` persistence namespace unless a migration path is included.
3. Do not add cloud AI, telemetry, analytics, or silent mailbox/network access.
4. Keep Apple Intelligence prompts evidence-grounded and conservative.
5. Avoid sending live SwiftData model objects across concurrency boundaries; snapshot mutable state first.
6. Keep heavy OCR/Foundation Models operations bounded for 16 GB unified-memory Macs.
7. Build with Swift 6 strict concurrency enabled and resolve warnings where practical.

For UI changes, preserve native macOS behavior and keyboard/accessibility support rather than replacing system components with custom imitations.
