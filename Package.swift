// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EntropyShieldIncidentTracker",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "IncidentTracker", targets: ["IncidentTracker"])
    ],
    targets: [
        .executableTarget(
            name: "IncidentTracker",
            path: "Sources/IncidentTracker"
        )
    ]
)
