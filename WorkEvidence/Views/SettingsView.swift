import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage("coreRoleDefinition") private var coreRoleDefinition = "Password resets, routine account access, basic desktop support, and other duties explicitly assigned to my primary IT support role."
    @AppStorage("expectedOtherPercent") private var expectedOtherPercent = 10.0
    @AppStorage("autoScanEvidenceInbox") private var autoScanEvidenceInbox = true

    @AppStorage("appleMailIntegrationEnabled") private var appleMailIntegrationEnabled = false
    @AppStorage("appleMailAccountName") private var appleMailAccountName = ""
    @AppStorage("appleMailMailboxPath") private var appleMailMailboxPath = ""
    @AppStorage("appleMailScanIntervalMinutes") private var appleMailScanIntervalMinutes = 15.0
    @AppStorage("appleMailCreateDraftsAutomatically") private var appleMailCreateDraftsAutomatically = true
    @AppStorage("appleMailAutoAnalyze") private var appleMailAutoAnalyze = true

    @AppStorage("requestMailIntegrationEnabled") private var requestMailIntegrationEnabled = false
    @AppStorage("requestMailAccountName") private var requestMailAccountName = ""
    @AppStorage("requestMailMailboxPath") private var requestMailMailboxPath = ""
    @AppStorage("requestMailScanIntervalMinutes") private var requestMailScanIntervalMinutes = 10.0
    @AppStorage("requestMailAutoAnalyze") private var requestMailAutoAnalyze = false

    @State private var availableMailboxes: [AppleMailMailboxDescriptor] = []
    @State private var mailStatus: String?
    @State private var isRefreshingMailboxes = false
    @State private var requestMailStatus: String?

    private var selectedMailboxID: Binding<String> {
        Binding(
            get: {
                guard !appleMailAccountName.isEmpty, !appleMailMailboxPath.isEmpty else { return "" }
                return appleMailAccountName + "\u{1F}" + appleMailMailboxPath
            },
            set: { newValue in
                guard let match = availableMailboxes.first(where: { $0.id == newValue }) else { return }
                appleMailAccountName = match.accountName
                appleMailMailboxPath = match.mailboxPath
            }
        )
    }

    var body: some View {
        Form {
            Section("Role Baseline") {
                Text("Scope Drift compares documented accomplishments against what your job is actually supposed to cover. Define the baseline in plain language; Apple Intelligence uses it only for local inference.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                TextEditor(text: $coreRoleDefinition)
                    .frame(minHeight: 120)

                HStack {
                    Text("Expected Other / Adjacent Work")
                    Spacer()
                    Slider(value: $expectedOtherPercent, in: 0...50, step: 1)
                        .frame(minWidth: 180, idealWidth: 260, maxWidth: 360)
                    Text("\(Int(expectedOtherPercent))%")
                        .monospacedDigit()
                        .frame(width: 42, alignment: .trailing)
                }
            }

            Section("Apple Mail Integration") {
                Toggle("Use Apple Mail as an evidence intake source", isOn: $appleMailIntegrationEnabled)

                Text("Choose one dedicated mailbox in Mail. Accomplishment Tracker reads only that mailbox, remembers message IDs it already processed, and turns new messages into reviewable evidence drafts.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                HStack {
                    Picker("Evidence mailbox", selection: selectedMailboxID) {
                        if selectedMailboxID.wrappedValue.isEmpty {
                            Text("No mailbox selected").tag("")
                        }
                        ForEach(availableMailboxes) { mailbox in
                            Text(mailbox.displayName).tag(mailbox.id)
                        }
                    }
                    .disabled(!appleMailIntegrationEnabled || availableMailboxes.isEmpty)

                    Button(isRefreshingMailboxes ? "Refreshing…" : "Refresh Mailboxes") {
                        refreshMailboxes()
                    }
                    .disabled(!appleMailIntegrationEnabled || isRefreshingMailboxes)
                }

                if !appleMailAccountName.isEmpty, !appleMailMailboxPath.isEmpty {
                    LabeledContent("Selected") {
                        Text("\(appleMailAccountName) / \(appleMailMailboxPath)")
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }

                HStack {
                    Text("Scan interval")
                    Spacer()
                    Slider(value: $appleMailScanIntervalMinutes, in: 5...60, step: 5)
                        .frame(minWidth: 180, idealWidth: 260, maxWidth: 360)
                        .disabled(!appleMailIntegrationEnabled)
                    Text("\(Int(appleMailScanIntervalMinutes)) min")
                        .monospacedDigit()
                        .frame(width: 58, alignment: .trailing)
                }

                Toggle("Create reviewable accomplishment drafts from new messages", isOn: $appleMailCreateDraftsAutomatically)
                    .disabled(!appleMailIntegrationEnabled)
                Toggle("Automatically run local Apple Intelligence on imported mail", isOn: $appleMailAutoAnalyze)
                    .disabled(!appleMailIntegrationEnabled || !appleMailCreateDraftsAutomatically)

                HStack {
                    Button("Test Mail Access") { testMailAccess() }
                        .disabled(!appleMailIntegrationEnabled || appleMailAccountName.isEmpty || appleMailMailboxPath.isEmpty)
                    Button("Scan Selected Mailbox Now") { scanMailNow() }
                        .disabled(!appleMailIntegrationEnabled || appleMailAccountName.isEmpty || appleMailMailboxPath.isEmpty)
                    Spacer()
                }

                if let mailStatus {
                    Label(mailStatus, systemImage: mailStatus.hasPrefix("Ready") || mailStatus.hasPrefix("Imported") ? "checkmark.circle" : "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("On first use, macOS will ask permission for Accomplishment Tracker to control Mail. If you decline, you can change it later in System Settings > Privacy & Security > Automation. No Outlook, Microsoft Graph, OAuth tokens, or mailbox passwords are stored by this app.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }


            Section("Experimental — Request Intelligence") {
                Toggle("Use a second Apple Mail mailbox for incoming requests", isOn: $requestMailIntegrationEnabled)

                Text("This mailbox is separate from accomplishment evidence. It is an experimental intake lane for new work requests. Local Apple Intelligence can digest each request, recall relevant prior accomplishment context, and draft a useful response for you to review and edit.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Picker("Request mailbox", selection: Binding(
                    get: {
                        guard !requestMailAccountName.isEmpty, !requestMailMailboxPath.isEmpty else { return "" }
                        return requestMailAccountName + "\u{1F}" + requestMailMailboxPath
                    },
                    set: { value in
                        guard let match = availableMailboxes.first(where: { $0.id == value }) else { return }
                        requestMailAccountName = match.accountName
                        requestMailMailboxPath = match.mailboxPath
                    }
                )) {
                    Text("No request mailbox selected").tag("")
                    ForEach(availableMailboxes) { mailbox in Text(mailbox.displayName).tag(mailbox.id) }
                }
                .disabled(!requestMailIntegrationEnabled || availableMailboxes.isEmpty)

                HStack {
                    Text("Scan interval")
                    Spacer()
                    Slider(value: $requestMailScanIntervalMinutes, in: 5...60, step: 5)
                        .frame(minWidth: 180, idealWidth: 260, maxWidth: 360)
                        .disabled(!requestMailIntegrationEnabled)
                    Text("\(Int(requestMailScanIntervalMinutes)) min").monospacedDigit().frame(width: 58, alignment: .trailing)
                }

                Toggle("Automatically analyze imported requests", isOn: $requestMailAutoAnalyze)
                    .disabled(!requestMailIntegrationEnabled)

                HStack {
                    Button("Test Request Mailbox") {
                        do {
                            try AppleMailIntegrationService.testAccess(accountName: requestMailAccountName, mailboxPath: requestMailMailboxPath)
                            requestMailStatus = "Ready: request mailbox is accessible."
                        } catch { requestMailStatus = error.localizedDescription }
                    }
                    .disabled(!requestMailIntegrationEnabled || requestMailAccountName.isEmpty || requestMailMailboxPath.isEmpty)
                    Spacer()
                }

                if let requestMailStatus {
                    Text(requestMailStatus).font(.caption).foregroundStyle(.secondary)
                }

                Text("Request Intelligence remains fully local to Accomplishment Tracker and does not hand work items to another Entropy Shield application in this standalone build.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section("Automatic Ingestion") {
                Toggle("Scan Evidence Inbox when the app becomes active", isOn: $autoScanEvidenceInbox)
                Text("Drop screenshots, PDFs, text notes, Markdown, logs, or structured JSON into the local Evidence Inbox. Each item becomes a reviewable accomplishment draft. Processed files are moved into a Processed subfolder.")
                    .font(.callout).foregroundStyle(.secondary)
                HStack {
                    Button("Reveal Evidence Inbox") { IngestionService.revealInbox() }
                    Spacer()
                    Text("Local automation URL: accomplishmenttracker://capture?title=...&note=...&source=...")
                        .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                }
            }

            Section("MacBook Performance") {
                Label("Optimized for M3 / 16 GB", systemImage: "memorychip")
                    .font(.headline)
                Text(M3ResourcePolicy.profileDescription)
                    .font(.callout).foregroundStyle(.secondary)
                Text("Mail scans are capped at \(AppleMailIntegrationService.maxMessagesPerScan) messages per pass. Local AI enrichment remains sequential so Mail ingestion, OCR, SwiftData, and Apple Intelligence do not compete for the same 16 GB unified-memory pool all at once.")
                    .font(.callout).foregroundStyle(.secondary)
            }

            Section("Data Guidance") {
                Text("Use Accomplishment Tracker for professional accomplishment records and supporting documentation. Avoid passwords, authentication secrets, regulated personal data, or information your employer prohibits from being copied locally.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(minWidth: 680, minHeight: 560)
    }

    @MainActor
    private func refreshMailboxes() {
        isRefreshingMailboxes = true
        defer { isRefreshingMailboxes = false }
        do {
            availableMailboxes = try AppleMailIntegrationService.availableMailboxes()
            if availableMailboxes.isEmpty {
                mailStatus = "Mail is reachable, but no mailboxes were returned."
            } else {
                mailStatus = "Ready: found \(availableMailboxes.count) Mail mailbox\(availableMailboxes.count == 1 ? "" : "es")."
                if selectedMailboxID.wrappedValue.isEmpty, let first = availableMailboxes.first {
                    appleMailAccountName = first.accountName
                    appleMailMailboxPath = first.mailboxPath
                }
            }
        } catch {
            mailStatus = error.localizedDescription
        }
    }

    @MainActor
    private func testMailAccess() {
        do {
            try AppleMailIntegrationService.testAccess(accountName: appleMailAccountName, mailboxPath: appleMailMailboxPath)
            mailStatus = "Ready: Accomplishment Tracker can read the selected Mail mailbox."
        } catch {
            mailStatus = error.localizedDescription
        }
    }

    @MainActor
    private func scanMailNow() {
        do {
            let imported = try AppleMailIntegrationService.importNewMessages(accountName: appleMailAccountName, mailboxPath: appleMailMailboxPath, modelContext: modelContext)
            mailStatus = imported.isEmpty ? "No new messages were waiting in the selected mailbox." : "Imported \(imported.count) new Mail message\(imported.count == 1 ? "" : "s") as evidence drafts."
        } catch {
            mailStatus = error.localizedDescription
        }
    }
}
