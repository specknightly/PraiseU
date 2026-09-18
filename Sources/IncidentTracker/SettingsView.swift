import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var incidentStore: IncidentStore
    @EnvironmentObject private var accomplishmentStore: AccomplishmentStore
    @EnvironmentObject private var workGraphStore: WorkGraphStore
    @EnvironmentObject private var preventionLedgerStore: PreventionLedgerStore

    @AppStorage("coreRoleDefinition") private var coreRoleDefinition = "Password resets, routine account access, basic desktop support, and other duties explicitly assigned to my primary IT support role."
    @AppStorage("expectedOtherPercent") private var expectedOtherPercent = 10.0
    @AppStorage("autoScanEvidenceInbox") private var autoScanEvidenceInbox = true
    @AppStorage("showMenuBarQuickCapture") private var showMenuBarQuickCapture = true
    @AppStorage("appleMailAutoScan") private var appleMailAutoScan = false
    @AppStorage("evidenceMailAccount") private var evidenceMailAccount = ""
    @AppStorage("evidenceMailPath") private var evidenceMailPath = ""

    @State private var storageStatus = ""
    @State private var validation = WorkRecordStorage.validate(root: WorkRecordStorage.rootURL)

    var body: some View {
        Form {
            Section("Database Location") {
                LabeledContent("Current repository") {
                    Text(WorkRecordStorage.rootURL.path).font(.caption.monospaced()).textSelection(.enabled)
                }
                Text("Incidents, accomplishments, evidence files, Work Graph relationships, Prevention Ledger records, backups, and the Evidence Inbox are kept under this single repository root.")
                    .font(.callout).foregroundStyle(.secondary)
                HStack {
                    Button("Reveal in Finder") { WorkRecordStorage.revealCurrentRoot() }
                    Button("Validate Database") { refreshValidation() }
                    Button("Link Existing Database…") { linkExisting() }
                    Button("Move Current Database…") { moveCurrent() }
                    Spacer()
                    Button("Use Default Location") { useDefault() }
                }
                HStack(spacing: 18) {
                    Label("\(validation.incidentCount) incidents", systemImage: "exclamationmark.triangle")
                    Label("\(validation.accomplishmentCount) accomplishments", systemImage: "trophy")
                    Label("\(workGraphStore.links.count) graph links", systemImage: "link")
                    Label("\(preventionLedgerStore.totalCount) prevention records", systemImage: "shield.checkered")
                    Label(ByteCountFormatter.string(fromByteCount: validation.totalBytes, countStyle: .file), systemImage: "externaldrive")
                }.font(.caption).foregroundStyle(.secondary)
                Text(validation.message).font(.caption).foregroundStyle(validation.isValid ? ESTheme.gold : .red)
                if !storageStatus.isEmpty { Text(storageStatus).font(.caption).foregroundStyle(.secondary) }
            }

            Section("Role Baseline & Scope") {
                Text("Apple Intelligence compares accomplishments against this baseline when estimating scope drift, work level, and review arguments.").font(.callout).foregroundStyle(.secondary)
                TextEditor(text: $coreRoleDefinition).frame(minHeight: 110)
                HStack {
                    Text("Expected adjacent / out-of-role work")
                    Spacer()
                    Slider(value: $expectedOtherPercent, in: 0...50, step: 1).frame(width: 280)
                    Text("\(Int(expectedOtherPercent))%").monospacedDigit().frame(width: 44)
                }
            }

            Section("Capture & Intake") {
                Toggle("Show menu-bar Quick Capture", isOn: $showMenuBarQuickCapture)
                Toggle("Scan Evidence Inbox when the app becomes active", isOn: $autoScanEvidenceInbox)
                Toggle("Scan selected Apple Mail evidence mailbox when the app becomes active", isOn: $appleMailAutoScan)
                if !evidenceMailAccount.isEmpty && !evidenceMailPath.isEmpty {
                    LabeledContent("Evidence mailbox") { Text("\(evidenceMailAccount) / \(evidenceMailPath)").font(.caption).foregroundStyle(.secondary) }
                } else {
                    Text("Choose an evidence mailbox under Accomplishments → Automation & Intake before enabling automatic Mail scanning.").font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Button("Reveal Evidence Inbox") { AccomplishmentIntakeService.revealInbox() }
                    Text(WorkRecordStorage.evidenceInboxURL.path).font(.caption.monospaced()).foregroundStyle(.secondary).textSelection(.enabled)
                }
            }

            Section("Data Guidance") {
                Text("This is a local professional work record, not a secrets vault. Avoid passwords, authentication tokens, regulated personal data, or information your employer prohibits from being copied locally.").font(.callout).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped).padding().frame(minWidth: 760, minHeight: 600)
        .onAppear { refreshValidation() }
    }

    private func refreshValidation() { validation = WorkRecordStorage.validate(root: WorkRecordStorage.rootURL) }

    private func linkExisting() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = true; panel.allowsMultipleSelection = false; panel.prompt = "Link Database"
        guard panel.runModal() == .OK, let chosen = panel.url else { return }
        let url: URL
        if chosen.hasDirectoryPath { url = chosen }
        else if chosen.lastPathComponent == "incidents.json" { url = chosen.deletingLastPathComponent() }
        else if chosen.lastPathComponent == "accomplishments.json" { url = chosen.deletingLastPathComponent().deletingLastPathComponent() }
        else { storageStatus = "Choose a Work Record repository folder, incidents.json, or accomplishments.json."; return }
        let check = WorkRecordStorage.validate(root: url)
        let hasRecognizedDatabase = FileManager.default.fileExists(atPath: url.appendingPathComponent("incidents.json").path) || FileManager.default.fileExists(atPath: url.appendingPathComponent("Accomplishments/accomplishments.json").path)
        guard check.isValid && hasRecognizedDatabase else { storageStatus = hasRecognizedDatabase ? check.message : "No recognized Entropy Shield database was found in that location."; return }
        WorkRecordStorage.setRoot(url); reloadStores(); validation = check; storageStatus = "Linked existing repository successfully."
    }

    private func moveCurrent() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.allowsMultipleSelection = false; panel.canCreateDirectories = true; panel.prompt = "Move Here"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try WorkRecordStorage.moveRepository(to: url); reloadStores(); refreshValidation(); storageStatus = "Database moved and validated successfully." }
        catch { storageStatus = error.localizedDescription }
    }

    private func useDefault() {
        WorkRecordStorage.setRoot(nil)
        do { try WorkRecordStorage.prepareRoot() } catch { storageStatus = error.localizedDescription; return }
        reloadStores(); refreshValidation(); storageStatus = "Using the default Application Support repository."
    }

    private func reloadStores() {
        incidentStore.reloadFromStorage()
        accomplishmentStore.reloadFromStorage()
        workGraphStore.reloadFromStorage()
        preventionLedgerStore.reloadFromStorage()
    }
}
