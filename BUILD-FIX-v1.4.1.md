# Build Fix v1.4.1

## Fix

The v1.4.0 app declared `MenuBarExtra` inside a conditional `if` within the SwiftUI `SceneBuilder`. Under the current Swift 6.2 / macOS 27 Xcode beta toolchain, that caused the compiler to fail at `var body: some Scene` without producing a useful diagnostic.

The menu-bar item now uses SwiftUI's supported `MenuBarExtra(_:systemImage:isInserted:content:)` initializer with the existing `@AppStorage` preference as its binding. This preserves the Settings toggle while keeping the scene graph structurally stable.

No data schema or repository format changes are included in this build-fix release.
