import SwiftUI
import SwiftData
import AppKit

struct RequestIntelligenceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RequestItem.receivedAt, order: .reverse) private var requests: [RequestItem]
    @Query(sort: \Accomplishment.date, order: .reverse) private var accomplishments: [Accomplishment]

    @AppStorage("requestMailIntegrationEnabled") private var integrationEnabled = false
    @AppStorage("requestMailAccountName") private var accountName = ""
    @AppStorage("requestMailMailboxPath") private var mailboxPath = ""
    @State private var selectedID: UUID?
    @State private var isAnalyzing = false
    @State private var status: String?

    private var selected: RequestItem? { requests.first(where: { $0.id == selectedID }) }

    var body: some View {
        NavigationSplitView {
            List(requests, selection: $selectedID) { request in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(request.subject).font(.headline).lineLimit(2)
                        Spacer()
                        Text(request.priority).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(request.sender).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    Text(request.receivedAt, style: .date).font(.caption2).foregroundStyle(.tertiary)
                }
                .tag(request.id)
                .padding(.vertical, 4)
            }
            .scrollContentBackground(.hidden)
            .entropyShieldBackdrop()
            .navigationTitle("Request Inbox")
            .navigationSplitViewColumnWidth(min: 300, ideal: 360, max: 480)
        } detail: {
            if let request = selected {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(request.subject).font(.title2.bold()).foregroundStyle(Color.entropyShieldGold)
                                Text("From \(request.sender)").foregroundStyle(Color.entropyShieldText.opacity(0.75))
                            }
                            Spacer()
                            Text(request.priority).font(.headline).foregroundStyle(Color.entropyShieldGold)
                        }

                        GroupBox("Request Digest") { Text(request.digest.isEmpty ? "Not analyzed yet." : request.digest).frame(maxWidth: .infinity, alignment: .leading).padding(6) }
                        GroupBox("Contextual Recall") { Text(request.inferredContext.isEmpty ? "Analysis can connect this request to prior accomplishment evidence when relevant." : request.inferredContext).frame(maxWidth: .infinity, alignment: .leading).padding(6) }
                        GroupBox("Draft Response") {
                            TextEditor(text: Binding(get: { request.draftResponse }, set: { request.draftResponse = $0; request.updatedAt = .now }))
                                .frame(minHeight: 180)
                                .padding(4)
                        }
                        DisclosureGroup("Original Mail") {
                            Text(request.body).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
                        }

                        HStack {
                            Button(isAnalyzing ? "Analyzing…" : "Analyze + Draft Response") { Task { await analyze(request) } }
                                .disabled(isAnalyzing)
                            Button("Copy Draft") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(request.draftResponse, forType: .string) }
                                .disabled(request.draftResponse.isEmpty)
                            Spacer()
                        }
                    }
                    .padding(24)
                }
                .entropyShieldBackdrop()
                .navigationTitle("Request Intelligence")
            } else {
                ContentUnavailableView("Select a request", systemImage: "tray.2", description: Text("New mail from the experimental request mailbox appears here for local analysis and response drafting."))
                    .entropyShieldBackdrop()
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button("Scan Request Mailbox") { scan() }
                    .disabled(!integrationEnabled || accountName.isEmpty || mailboxPath.isEmpty)
            }
        }
        .alert("Request Intelligence", isPresented: Binding(get: { status != nil }, set: { if !$0 { status = nil } })) {
            Button("OK", role: .cancel) { status = nil }
        } message: { Text(status ?? "") }
    }

    private func scan() {
        do {
            let imported = try RequestIntelligenceService.importNewRequests(accountName: accountName, mailboxPath: mailboxPath, modelContext: modelContext)
            if let first = imported.first { selectedID = first.id }
            status = imported.isEmpty ? "No new requests were found." : "Imported \(imported.count) new request\(imported.count == 1 ? "" : "s")."
        } catch { status = error.localizedDescription }
    }

    private func analyze(_ request: RequestItem) async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            let knowledge = RequestIntelligenceService.priorKnowledge(for: request, accomplishments: accomplishments)
            let result = try await RequestIntelligenceService.analyze(.init(subject: request.subject, sender: request.sender, body: request.body, priorKnowledge: knowledge))
            request.digest = result.digest
            request.inferredContext = result.context
            request.priority = result.priority
            request.draftResponse = result.response
            request.status = "Analyzed"
            request.updatedAt = .now
            try? modelContext.save()
        } catch { status = error.localizedDescription }
    }

}
