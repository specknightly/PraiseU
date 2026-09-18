import AppKit
import SwiftUI

@main
struct IncidentTrackerApp: App {
    init() {
        NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
    }

    @StateObject private var incidentStore = IncidentStore()
    @StateObject private var accomplishmentStore = AccomplishmentStore()
    @StateObject private var workGraphStore = WorkGraphStore()
    @StateObject private var preventionLedgerStore = PreventionLedgerStore()
    @StateObject private var operationalBurdenStore = OperationalBurdenStore()
    @StateObject private var responsibilityDriftStore = ResponsibilityDriftStore()
    @AppStorage("showMenuBarQuickCapture") private var showMenuBarQuickCapture = true

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(incidentStore)
                .environmentObject(accomplishmentStore)
                .environmentObject(workGraphStore)
                .environmentObject(preventionLedgerStore)
                .environmentObject(operationalBurdenStore)
                .environmentObject(responsibilityDriftStore)
                .preferredColorScheme(.dark)
                .tint(ESTheme.accent)
                .frame(minWidth: 1180, minHeight: 760)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Accomplishment") { _ = accomplishmentStore.createAccomplishment() }.keyboardShortcut("n", modifiers:[.command,.shift])
            }
        }
        MenuBarExtra(
            "Quick Capture",
            systemImage: "square.and.pencil",
            isInserted: $showMenuBarQuickCapture
        ) {
            QuickCaptureView()
                .environmentObject(accomplishmentStore)
                .environmentObject(workGraphStore)
                .preferredColorScheme(.dark)
                .tint(ESTheme.accent)
        }
        Settings {
            SettingsView()
                .environmentObject(incidentStore)
                .environmentObject(accomplishmentStore)
                .environmentObject(workGraphStore)
                .environmentObject(preventionLedgerStore)
                .environmentObject(operationalBurdenStore)
                .environmentObject(responsibilityDriftStore)
                .preferredColorScheme(.dark)
                .tint(ESTheme.accent)
        }
    }
}
