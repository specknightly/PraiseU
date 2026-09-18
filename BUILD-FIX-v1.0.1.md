# Entropy Shield Incident Tracker v1.0.1

## Build fix

Fixed the SwiftUI compiler error in `TimelineView.swift`:

- Invalid: `.frame(width: 2, minHeight: 155)`
- Fixed by separating the fixed-width and flexible-height frame modifiers:
  - `.frame(width: 2)`
  - `.frame(minHeight: 155)`

The original form attempted to mix parameters from SwiftUI's fixed-size `frame(width:height:alignment:)` overload with parameters from its flexible `frame(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:alignment:)` overload.

## Validation performed

- Scanned all project Swift sources for the same invalid `frame` parameter combination.
- Parsed every Swift source file with Swift 6.2.1.
- Confirmed `Build-App.command` syntax remains valid.

This environment does not include the macOS 27 SDK, so final AppKit/SwiftUI linking still occurs on the target Mac via `Build-App.command`.
