import SwiftUI
import SwiftData

@main
struct WorkEvidenceApp: App {
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

    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 1100, minHeight: 720)
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

        Settings {
            SettingsView()
                .frame(minWidth: 680, idealWidth: 820, minHeight: 560, idealHeight: 760)
                .modelContainer(container)
        }
    }
}

extension Notification.Name {
    static let newAccomplishment = Notification.Name("WorkEvidence.newAccomplishment")
}
