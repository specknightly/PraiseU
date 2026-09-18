# Entropy Shield Incident Tracker v1.0.2

## Build repair

This release contains the SwiftUI Timeline fix and adds a clean-build safeguard.

### Fixed compiler error

The invalid SwiftUI call:

```swift
.frame(width: 2, minHeight: 155)
```

uses parameters from two different `frame` overloads. It is now:

```swift
.frame(width: 2)
.frame(minHeight: 155)
```

### Clean build safeguard

`Build-App.command` now removes stale SwiftPM build artifacts before release compilation. This prevents an older `.build` directory from compiling source from a previous extracted copy.

### Important

Build this v1.0.2 folder, not the older `EntropyShield-IncidentTracker-v1.0 2` folder shown in the failing terminal log.
