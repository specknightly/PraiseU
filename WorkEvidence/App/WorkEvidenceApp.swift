import SwiftUI
import SwiftData

@main
struct WorkEvidenceApp: App {
    @AppStorage("showMenuBarQuickCapture") private var showMenuBarQuickCapture = true

    private let container: ModelContainer = {
        let schema = Schema([
            Accomplishment.self,
            EvidenceAttachment.self,
            RequestItem.self
        ])

        let configuration = ModelConfiguration(
            "WorkEvidence",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create local Accomplishment Tracker database: \(error)")
        }
    }()

    init() {
        QuickCaptureHotKeyController.shared.activate(modelContainer: container)
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            RootView()
                .frame(minWidth: 1100, minHeight: 720)
                .preferredColorScheme(.dark)
                .tint(EntropyShieldTheme.gold)
        }
        .modelContainer(container)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Accomplishment") {
                    NotificationCenter.default.post(name: .newAccomplishment, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }

        MenuBarExtra("Quick Capture", systemImage: "square.and.pencil", isInserted: $showMenuBarQuickCapture) {
            QuickCaptureView()
                .modelContainer(container)
                .preferredColorScheme(.dark)
                .tint(EntropyShieldTheme.gold)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .frame(minWidth: 680, idealWidth: 820, minHeight: 560, idealHeight: 760)
                .modelContainer(container)
                .preferredColorScheme(.dark)
                .tint(EntropyShieldTheme.gold)
        }
    }
}

extension Notification.Name {
    static let newAccomplishment = Notification.Name("WorkEvidence.newAccomplishment")
    static let revealAccomplishment = Notification.Name("WorkEvidence.revealAccomplishment")
}
