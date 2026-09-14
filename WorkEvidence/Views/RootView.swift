import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

private enum LibraryScope: String, CaseIterable, Identifiable {
    case all = "All Evidence"
    case thisYear = "This Year"
    case pinned = "Pinned"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .all: "tray.full"
        case .thisYear: "calendar"
        case .pinned: "pin.fill"
        }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Accomplishment.date, order: .reverse) private var entries: [Accomplishment]

    @State private var scope: LibraryScope = .thisYear
    @State private var categoryFilter: AccomplishmentCategory?
    @State private var searchText = ""
    @State private var selectedEntryID: UUID?
    @State private var showingDeleteConfirmation = false
    @State private var exportError: String?
    @State private var isGeneratingBragDocument = false
    @State private var isGeneratingValueModel = false
    @State private var ingestionStatus: String?
    @State private var showingInsights = false
    @State private var showingRequestIntelligence = false
    @State private var showingLargeExportWarning = false
    @State private var pendingLargeExportBytes: Int64 = 0
    @State private var mailScanTask: Task<Void, Never>?
    @State private var mailEnrichmentProgress: (done: Int, total: Int)?
    @State private var isMailScanActive = false
    @AppStorage("autoScanEvidenceInbox") private var autoScanEvidenceInbox = true
    @AppStorage("appleMailIntegrationEnabled") private var appleMailIntegrationEnabled = false
    @AppStorage("appleMailAccountName") private var appleMailAccountName = ""
    @AppStorage("appleMailMailboxPath") private var appleMailMailboxPath = ""
    @AppStorage("appleMailScanIntervalMinutes") private var appleMailScanIntervalMinutes = 15.0
    @AppStorage("appleMailAutoAnalyze") private var appleMailAutoAnalyze = true
    @AppStorage("appleMailCreateDraftsAutomatically") private var appleMailCreateDraftsAutomatically = true
    @AppStorage("requestMailIntegrationEnabled") private var requestMailIntegrationEnabled = false
    @AppStorage("requestMailAccountName") private var requestMailAccountName = ""
    @AppStorage("requestMailMailboxPath") private var requestMailMailboxPath = ""
    @AppStorage("requestMailScanIntervalMinutes") private var requestMailScanIntervalMinutes = 10.0
    @AppStorage("requestMailAutoAnalyze") private var requestMailAutoAnalyze = false
    @AppStorage("coreRoleDefinition") private var coreRoleDefinition = "Password resets, routine account access, basic desktop support, and other duties explicitly assigned to my primary IT support role."
    @AppStorage("expectedOtherPercent") private var expectedOtherPercent = 10.0

    private var currentYear: Int { Calendar.current.component(.year, from: .now) }

    private var filteredEntries: [Accomplishment] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return entries.filter { entry in
            let scopeMatches: Bool = {
                switch scope {
                case .all: true
                case .thisYear: Calendar.current.component(.year, from: entry.date) == currentYear
                case .pinned: entry.isPinned
                }
            }()

            let categoryMatches = categoryFilter == nil || entry.category == categoryFilter
            let searchMatches = normalizedSearch.isEmpty || entry.searchBlob.contains(normalizedSearch)

            return scopeMatches && categoryMatches && searchMatches
        }
    }

    private var selectedEntry: Accomplishment? {
        guard let selectedEntryID else { return nil }
        return entries.first(where: { $0.id == selectedEntryID })
    }

    var body: some View {
        Group {
            if showingRequestIntelligence {
                NavigationSplitView {
                    sidebar
                        .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
                } detail: {
                    RequestIntelligenceView()
                }
            } else if showingInsights {
                NavigationSplitView {
                    sidebar
                        .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
                } detail: {
                    InsightsView(entries: entries)
                }
            } else {
                NavigationSplitView {
                    sidebar
                        .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
                } content: {
                    evidenceList
                        .navigationSplitViewColumnWidth(min: 330, ideal: 390, max: 520)
                } detail: {
                    Group {
                        if let selectedEntry {
                            EntryEditorView(entry: selectedEntry)
                        } else {
                            ContentUnavailableView(
                                "Select an accomplishment",
                                systemImage: "doc.text.magnifyingglass",
                                description: Text("Choose an entry from the evidence list, or create a new one.")
                            )
                        }
                    }
                    .navigationSplitViewColumnWidth(min: 460, ideal: 620)
                }
            }
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search accomplishments")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: addEntry) {
                    Label("New Accomplishment", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])

                Menu {
                    Button("Export \(currentYear) Review Packet…", action: exportCurrentYear)
                    Button("Generate AI Brag Document…") { Task { await generateBragDocument() } }
                        .disabled(isGeneratingBragDocument || !AppleIntelligenceEnrichmentService.availability.isAvailable)
                    Button("Generate Professional Value Model…") { Task { await generateProfessionalValueModel() } }
                        .disabled(isGeneratingValueModel || !AppleIntelligenceEnrichmentService.availability.isAvailable)
                    Divider()
                    Button("Scan Evidence Inbox Now") {
                        scanEvidenceInbox()
                    }
                    Button("Scan Apple Mail Now") {
                        mailScanTask = Task { await scanAppleMail(silentWhenEmpty: false) }
                    }
                    .disabled(!appleMailIntegrationEnabled || appleMailAccountName.isEmpty || appleMailMailboxPath.isEmpty || isMailScanActive)
                    Button("Reveal Evidence Inbox in Finder") {
                        IngestionService.revealInbox()
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newAccomplishment)) { _ in addEntry() }
        .onReceive(NotificationCenter.default.publisher(for: .revealAccomplishment)) { notification in
            guard let id = notification.object as? UUID else { return }
            showingInsights = false
            showingRequestIntelligence = false
            scope = .all
            categoryFilter = nil
            selectedEntryID = id
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            if autoScanEvidenceInbox { scanEvidenceInbox(silentWhenEmpty: true) }
            if appleMailIntegrationEnabled && appleMailCreateDraftsAutomatically { mailScanTask = Task { await scanAppleMail(silentWhenEmpty: true) } }
            if requestMailIntegrationEnabled { Task { await scanRequestMail(silentWhenEmpty: true) } }
        }

        .task(id: "\(appleMailIntegrationEnabled)-\(appleMailCreateDraftsAutomatically)-\(appleMailScanIntervalMinutes)-\(appleMailAccountName)-\(appleMailMailboxPath)") {
            guard appleMailIntegrationEnabled, appleMailCreateDraftsAutomatically, !appleMailAccountName.isEmpty, !appleMailMailboxPath.isEmpty else { return }
            while !Task.isCancelled {
                let seconds = max(300.0, appleMailScanIntervalMinutes * 60.0)
                try? await Task.sleep(for: .seconds(seconds))
                guard !Task.isCancelled else { return }
                mailScanTask = Task { await scanAppleMail(silentWhenEmpty: true) }
            }
        }
        .task(id: "request-\(requestMailIntegrationEnabled)-\(requestMailScanIntervalMinutes)-\(requestMailAccountName)-\(requestMailMailboxPath)-\(requestMailAutoAnalyze)") {
            guard requestMailIntegrationEnabled, !requestMailAccountName.isEmpty, !requestMailMailboxPath.isEmpty else { return }
            while !Task.isCancelled {
                let seconds = max(300.0, requestMailScanIntervalMinutes * 60.0)
                try? await Task.sleep(for: .seconds(seconds))
                guard !Task.isCancelled else { return }
                await scanRequestMail(silentWhenEmpty: true)
            }
        }
        .onOpenURL { url in
            if let entry = IngestionService.ingestCaptureURL(url, modelContext: modelContext) {
                showingInsights = false
                showingRequestIntelligence = false
                selectedEntryID = entry.id
                scope = .all
                categoryFilter = nil
                ingestionStatus = "Captured a new accomplishment from a local automation."
            }
        }
        .alert("Evidence Inbox", isPresented: Binding(
            get: { ingestionStatus != nil },
            set: { if !$0 { ingestionStatus = nil } }
        )) {
            Button("OK", role: .cancel) { ingestionStatus = nil }
        } message: {
            Text(ingestionStatus ?? "")
        }
        .alert("Export Failed", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "Unknown export error")
        }
        .confirmationDialog(
            "Large Export",
            isPresented: $showingLargeExportWarning,
            titleVisibility: .visible
        ) {
            Button("Export Anyway") {
                let yearEntries = entries.filter { Calendar.current.component(.year, from: $0.date) == currentYear }
                performExportCurrentYear(yearEntries)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This export will embed about \(ByteCountFormatter.string(fromByteCount: pendingLargeExportBytes, countStyle: .file)) of evidence files and may be slow to open. Files over 20 MB are not embedded.")
        }
        .safeAreaInset(edge: .bottom) {
            if let progress = mailEnrichmentProgress {
                HStack(spacing: 12) {
                    ProgressView(value: Double(progress.done), total: Double(max(progress.total, 1)))
                        .frame(maxWidth: 220)
                    Text("Analyzing mail evidence \(progress.done)/\(progress.total)…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Cancel") { mailScanTask?.cancel() }
                        .buttonStyle(.borderless)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)
            }
        }
    }

    private var sidebar: some View {
        List {
            Section("Library") {
                ForEach(LibraryScope.allCases) { item in
                    Button {
                        showingInsights = false
                        showingRequestIntelligence = false
                        scope = item
                        categoryFilter = nil
                    } label: {
                        Label(item.rawValue, systemImage: item.symbol)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .fontWeight(scope == item && categoryFilter == nil ? .semibold : .regular)
                }
            }

            Section("Intelligence") {
                Button {
                    showingInsights = true
                    showingRequestIntelligence = false
                    categoryFilter = nil
                } label: {
                    Label("Professional Insights", systemImage: "chart.xyaxis.line")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .fontWeight(showingInsights ? .semibold : .regular)

                Button {
                    showingRequestIntelligence = true
                    showingInsights = false
                    categoryFilter = nil
                } label: {
                    Label("Request Intelligence (Experimental)", systemImage: "tray.2.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .fontWeight(showingRequestIntelligence ? .semibold : .regular)
            }

            Section("Categories") {
                ForEach(AccomplishmentCategory.allCases) { category in
                    Button {
                        showingInsights = false
                        scope = .all
                        categoryFilter = category
                    } label: {
                        HStack {
                            Label(category.rawValue, systemImage: category.symbol)
                            Spacer()
                            Text("\(entries.filter { $0.category == category }.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .fontWeight(categoryFilter == category ? .semibold : .regular)
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Image("EntropyShieldLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityLabel("Entropy Shield logo")

                Text("Developed by")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Peter Odintsov")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .navigationTitle("Accomplishment Tracker")
    }

    private var evidenceList: some View {
        VStack(spacing: 0) {
            YearSummaryView(entries: entries.filter { Calendar.current.component(.year, from: $0.date) == currentYear })
                .padding(14)

            Divider()

            if filteredEntries.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No evidence yet" : "No matches",
                    systemImage: searchText.isEmpty ? "square.and.pencil" : "magnifyingglass",
                    description: Text(searchText.isEmpty ? "Document the work now, while the details and impact are still fresh." : "Try a different search or filter.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredEntries, id: \.id) { entry in
                    EntryRow(entry: entry, isSelected: selectedEntryID == entry.id)
                        .contentShape(Rectangle())
                        .onTapGesture { showingInsights = false; showingRequestIntelligence = false; selectedEntryID = entry.id }
                        .contextMenu {
                            Button(entry.isPinned ? "Unpin" : "Pin") { entry.isPinned.toggle() }
                            Divider()
                            Button("Delete", role: .destructive) {
                                selectedEntryID = entry.id
                                showingDeleteConfirmation = true
                            }
                        }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle(categoryFilter?.rawValue ?? scope.rawValue)
        .confirmationDialog(
            "Delete this accomplishment?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Accomplishment", role: .destructive, action: deleteSelected)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The entry and its locally copied evidence files will be removed.")
        }
    }

    private func addEntry() {
        let entry = Accomplishment(
            date: .now,
            title: "New accomplishment",
            category: .infrastructure
        )
        modelContext.insert(entry)
        try? modelContext.save()
        scope = .all
        categoryFilter = nil
        showingInsights = false
        showingRequestIntelligence = false
        selectedEntryID = entry.id
    }

    private func deleteSelected() {
        guard let selectedEntry else { return }
        for attachment in selectedEntry.attachments {
            AttachmentStore.delete(relativePath: attachment.relativePath)
        }
        modelContext.delete(selectedEntry)
        try? modelContext.save()
        selectedEntryID = nil
    }

    @MainActor
    private func scanEvidenceInbox(silentWhenEmpty: Bool = false) {
        do {
            let count = try IngestionService.scanInbox(modelContext: modelContext)
            if count > 0 || !silentWhenEmpty {
                ingestionStatus = count == 0 ? "No new files were waiting in the Evidence Inbox." : "Imported \(count) new item\(count == 1 ? "" : "s") as accomplishment drafts."
            }
        } catch {
            ingestionStatus = "Evidence Inbox scan failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func scanRequestMail(silentWhenEmpty: Bool) async {
        guard requestMailIntegrationEnabled, !requestMailAccountName.isEmpty, !requestMailMailboxPath.isEmpty else { return }
        do {
            let imported = try RequestIntelligenceService.importNewRequests(accountName: requestMailAccountName, mailboxPath: requestMailMailboxPath, modelContext: modelContext)
            if requestMailAutoAnalyze, AppleIntelligenceEnrichmentService.availability.isAvailable {
                for request in imported {
                    let knowledge = RequestIntelligenceService.priorKnowledge(for: request, accomplishments: entries)
                    if let result = try? await RequestIntelligenceService.analyze(.init(subject: request.subject, sender: request.sender, body: request.body, priorKnowledge: knowledge)) {
                        request.digest = result.digest
                        request.inferredContext = result.context
                        request.priority = result.priority
                        request.draftResponse = result.response
                        request.status = "Analyzed"
                        request.updatedAt = .now
                    }
                }
                try? modelContext.save()
            }
            if !imported.isEmpty && !silentWhenEmpty { ingestionStatus = "Imported \(imported.count) new request\(imported.count == 1 ? "" : "s") into Request Intelligence." }
        } catch {
            if !silentWhenEmpty { ingestionStatus = "Request mailbox scan failed: \(error.localizedDescription)" }
        }
    }

    @MainActor
    private func scanAppleMail(silentWhenEmpty: Bool) async {
        guard appleMailIntegrationEnabled, !appleMailAccountName.isEmpty, !appleMailMailboxPath.isEmpty else { return }
        guard !isMailScanActive else { return }
        isMailScanActive = true
        defer { isMailScanActive = false; mailEnrichmentProgress = nil }
        do {
            let imported = try AppleMailIntegrationService.importNewMessages(
                accountName: appleMailAccountName,
                mailboxPath: appleMailMailboxPath,
                modelContext: modelContext
            )

            if appleMailAutoAnalyze, AppleIntelligenceEnrichmentService.availability.isAvailable {
                for (index, entry) in imported.enumerated() {
                    guard !Task.isCancelled else { break }
                    mailEnrichmentProgress = (done: index, total: imported.count)
                    let enrichmentInput = AccomplishmentEnrichmentInput(
                        title: entry.title,
                        category: entry.category.rawValue,
                        context: entry.context,
                        actionTaken: entry.actionTaken,
                        outcome: entry.outcome,
                        businessImpact: entry.businessImpact,
                        metrics: entry.metrics,
                        stakeholders: entry.stakeholders,
                        evidenceNotes: entry.evidenceNotes
                    )
                    if let humanValue = try? await AppleIntelligenceEnrichmentService.analyze(enrichmentInput) {
                        entry.humanValueAnalysis = humanValue
                        entry.humanValueGeneratedAt = .now
                    }
                    if let scope = try? await AppleIntelligenceEnrichmentService.inferScope(enrichmentInput, coreRoleDefinition: coreRoleDefinition) {
                        entry.responsibilityScope = scope.scope
                        entry.scopeInference = scope.analysis
                        entry.scopeInferenceGeneratedAt = .now
                    }

                    let professionalInput = ProfessionalIntelligenceInput(
                        title: entry.title,
                        context: entry.context,
                        actionTaken: entry.actionTaken,
                        outcome: entry.outcome,
                        businessImpact: entry.businessImpact,
                        metrics: entry.metrics,
                        stakeholders: entry.stakeholders,
                        responsibilityScope: entry.responsibilityScope,
                        evidenceAnalysis: entry.evidenceAnalysis,
                        attachmentCount: entry.attachments.count
                    )
                    if let professional = try? await EvidenceIntelligenceService.professionalIntelligence(input: professionalInput, coreRoleDefinition: coreRoleDefinition) {
                        entry.claimStrength = professional.claimStrength
                        entry.workLevel = professional.workLevel
                        entry.professionalIntelligence = professional.analysis
                        entry.professionalIntelligenceGeneratedAt = .now
                    }
                    entry.updatedAt = .now
                    try? modelContext.save()
                    mailEnrichmentProgress = (done: index + 1, total: imported.count)
                }
            }

            if !imported.isEmpty {
                selectedEntryID = imported.first?.id
                scope = .all
                categoryFilter = nil
            }
            if !silentWhenEmpty || !imported.isEmpty {
                ingestionStatus = imported.isEmpty
                    ? "No new messages were waiting in the selected Apple Mail mailbox."
                    : "Imported \(imported.count) new Mail message\(imported.count == 1 ? "" : "s") as evidence drafts\(appleMailAutoAnalyze ? " and ran local intelligence." : ".")"
            }
        } catch {
            if !silentWhenEmpty { ingestionStatus = "Apple Mail scan failed: \(error.localizedDescription)" }
        }
    }

    @MainActor
    private func generateProfessionalValueModel() async {
        guard !isGeneratingValueModel else { return }
        isGeneratingValueModel = true
        defer { isGeneratingValueModel = false }
        let yearEntries = entries.filter { Calendar.current.component(.year, from: $0.date) == currentYear }
        let analysisEntries = yearEntries.map(makeSummaryInput)
        do {
            let narrative = try await AppleIntelligenceEnrichmentService.generateProfessionalValueModel(
                entries: analysisEntries, year: currentYear, coreRoleDefinition: coreRoleDefinition, expectedOtherPercent: Int(expectedOtherPercent)
            )
            let html = ExportService.professionalValueModelHTML(narrative: narrative, entries: yearEntries, year: currentYear, expectedOtherPercent: Int(expectedOtherPercent))
            let panel = NSSavePanel()
            panel.title = "Export Professional Value Model"
            panel.nameFieldStringValue = "Accomplishment-Tracker-Professional-Value-Model-\(currentYear).html"
            panel.allowedContentTypes = [.html]
            panel.canCreateDirectories = true
            if panel.runModal() == .OK, let url = panel.url { try html.write(to: url, atomically: true, encoding: .utf8) }
        } catch { exportError = error.localizedDescription }
    }

    @MainActor
    private func generateBragDocument() async {
        guard !isGeneratingBragDocument else { return }
        isGeneratingBragDocument = true
        defer { isGeneratingBragDocument = false }
        let yearEntries = entries.filter { Calendar.current.component(.year, from: $0.date) == currentYear }
        let analysisEntries = yearEntries.map(makeSummaryInput)
        do {
            let narrative = try await AppleIntelligenceEnrichmentService.generateBragDocument(
                entries: analysisEntries, year: currentYear, coreRoleDefinition: coreRoleDefinition, expectedOtherPercent: Int(expectedOtherPercent)
            )
            let html = ExportService.bragDocumentHTML(narrative: narrative, entries: yearEntries, year: currentYear, expectedOtherPercent: Int(expectedOtherPercent))
            let panel = NSSavePanel()
            panel.title = "Export AI Brag Document"
            panel.nameFieldStringValue = "Accomplishment-Tracker-Brag-Document-\(currentYear).html"
            panel.allowedContentTypes = [.html]
            panel.canCreateDirectories = true
            let response = panel.runModal()
            if response == .OK, let url = panel.url { try html.write(to: url, atomically: true, encoding: .utf8) }
        } catch { exportError = error.localizedDescription }
    }

    private func makeSummaryInput(_ entry: Accomplishment) -> AccomplishmentSummaryInput {
        AccomplishmentSummaryInput(
            date: entry.date,
            title: entry.title,
            category: entry.category.rawValue,
            responsibilityScope: entry.responsibilityScope,
            workLevel: entry.workLevel,
            claimStrength: entry.claimStrength,
            actionTaken: entry.actionTaken,
            outcome: entry.outcome,
            businessImpact: entry.businessImpact,
            metrics: entry.metrics,
            attachmentCount: entry.attachments.count
        )
    }

    private func exportCurrentYear() {
        let yearEntries = entries.filter { Calendar.current.component(.year, from: $0.date) == currentYear }
        let totalEvidenceBytes = yearEntries.reduce(Int64(0)) { $0 + $1.attachments.reduce(Int64(0)) { $0 + $1.byteCount } }
        if totalEvidenceBytes > ExportService.recommendedExportWarningBytes {
            pendingLargeExportBytes = totalEvidenceBytes
            showingLargeExportWarning = true
            return
        }
        performExportCurrentYear(yearEntries)
    }

    private func performExportCurrentYear(_ yearEntries: [Accomplishment]) {
        let html = ExportService.annualReviewHTML(entries: yearEntries, year: currentYear)

        let panel = NSSavePanel()
        panel.title = "Export Annual Review Packet"
        panel.nameFieldStringValue = "Accomplishment-Tracker-\(currentYear).html"
        panel.allowedContentTypes = [.html]
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try html.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                exportError = error.localizedDescription
            }
        }
    }
}

private struct EntryRow: View {
    let entry: Accomplishment
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.title.isEmpty ? "Untitled accomplishment" : entry.title)
                    .font(.headline)
                    .lineLimit(2)
                Spacer(minLength: 10)
                if entry.humanValueAnalysis != nil {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .help("Human Value Analysis saved")
                }
                if entry.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(entry.outcome.isEmpty ? entry.actionTaken : entry.outcome)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Label(entry.category.rawValue, systemImage: entry.category.symbol)
                    .lineLimit(1)
                Spacer()
                Text(entry.date, format: .dateTime.month(.abbreviated).day().year())
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(isSelected ? Color.accentColor.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct YearSummaryView: View {
    let entries: [Accomplishment]

    private var thisMonth: Int {
        let calendar = Calendar.current
        return entries.filter {
            calendar.component(.month, from: $0.date) == calendar.component(.month, from: .now) &&
            calendar.component(.year, from: $0.date) == calendar.component(.year, from: .now)
        }.count
    }

    private var withMetrics: Int {
        entries.filter { !$0.metrics.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    private var aiEnriched: Int {
        entries.filter { $0.humanValueAnalysis != nil }.count
    }

    private var classified: [Accomplishment] { entries.filter { $0.responsibilityScope != .unclassified } }
    private var otherPercent: Int {
        guard !classified.isEmpty else { return 0 }
        return Int((Double(classified.filter { $0.responsibilityScope == .other }.count) / Double(classified.count) * 100).rounded())
    }

    var body: some View {
        HStack(spacing: 12) {
            metric(title: "This Year", value: entries.count, symbol: "calendar")
            metric(title: "This Month", value: thisMonth, symbol: "calendar.badge.clock")
            metric(title: "With Metrics", value: withMetrics, symbol: "chart.bar")
            metric(title: "AI Enriched", value: aiEnriched, symbol: "sparkles")
            metric(title: "Other Scope %", value: otherPercent, symbol: "arrow.up.right.circle")
        }
    }

    private func metric(title: String, value: Int, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title2.weight(.semibold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}
