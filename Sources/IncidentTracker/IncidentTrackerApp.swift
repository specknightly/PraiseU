import SwiftUI

@main
struct IncidentTrackerApp: App {
    @StateObject private var incidentStore = IncidentStore()
    @StateObject private var accomplishmentStore = AccomplishmentStore()
    @AppStorage("showMenuBarQuickCapture") private var showMenuBarQuickCapture = true

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(incidentStore)
                .environmentObject(accomplishmentStore)
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
        }
        Settings {
            SettingsView()
                .environmentObject(incidentStore)
                .environmentObject(accomplishmentStore)
        }
    }
}
