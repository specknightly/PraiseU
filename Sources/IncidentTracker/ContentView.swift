import AppKit
import SwiftUI

enum TrackerMode: String, CaseIterable, Identifiable {
    case incidents = "Incidents"
    case accomplishments = "Accomplishments"
    var id: String { rawValue }
    var symbol: String { self == .incidents ? "exclamationmark.triangle" : "trophy" }
}

struct ContentView: View {
    @EnvironmentObject private var incidentStore: IncidentStore
    @EnvironmentObject private var accomplishmentStore: AccomplishmentStore
    @EnvironmentObject private var workGraphStore: WorkGraphStore
    @Environment(\.openSettings) private var openSettings

    @State private var mode: TrackerMode = .incidents
    @State private var incidentSelection: SidebarSelection = .all
    @State private var selectedIncidentID: UUID?
    @State private var incidentSort: IncidentSort = .newest

    @State private var accomplishmentSelection: AccomplishmentSidebarSelection = .thisYear
    @State private var selectedAccomplishmentID: UUID?
    @State private var accomplishmentSort: AccomplishmentSort = .newest

    @State private var searchText = ""
    @State private var showingAbout = false
    @State private var showingWorkIntelligence = false
    @State private var showingWorkGraph = false
    @AppStorage("appleMailAutoScan") private var appleMailAutoScan = false
    @AppStorage("evidenceMailAccount") private var evidenceMailAccount = ""
    @AppStorage("evidenceMailPath") private var evidenceMailPath = ""

    private var filteredIncidents: [IncidentRecord] { incidentStore.filtered(selection: incidentSelection, searchText: searchText, sort: incidentSort) }
    private var filteredAccomplishments: [AccomplishmentRecord] { accomplishmentStore.filtered(selection: accomplishmentSelection, searchText: searchText, sort: accomplishmentSort) }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().overlay(ESTheme.border)
            if mode == .incidents { incidentBody } else { accomplishmentBody }
            Divider().overlay(ESTheme.border)
            if mode == .incidents { incidentStatusBar } else { accomplishmentStatusBar }
        }
        .background(ESTheme.canvas).foregroundStyle(.white)
        .onAppear { repairIncidentSelection(); repairAccomplishmentSelection(); performAutomaticIntake() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in performAutomaticIntake() }
        .onOpenURL { url in if let record = AccomplishmentIntakeService.ingest(url: url, store: accomplishmentStore) { mode = .accomplishments; accomplishmentSelection = .all; selectedAccomplishmentID = record.id } }
        .sheet(isPresented: $showingAbout) { AboutView() }
        .sheet(isPresented: $showingWorkIntelligence) { UnifiedWorkIntelligenceView().environmentObject(incidentStore).environmentObject(accomplishmentStore) }
        .sheet(isPresented: $showingWorkGraph) {
            WorkGraphView()
                .environmentObject(incidentStore)
                .environmentObject(accomplishmentStore)
                .environmentObject(workGraphStore)
        }
        .onChange(of: incidentSelection) { _, _ in repairIncidentSelection() }
        .onChange(of: accomplishmentSelection) { _, _ in repairAccomplishmentSelection() }
        .onChange(of: searchText) { _, _ in repairIncidentSelection(); repairAccomplishmentSelection() }
        .onChange(of: incidentStore.incidents) { _, _ in repairIncidentSelection() }
        .onChange(of: accomplishmentStore.accomplishments) { _, _ in repairAccomplishmentSelection() }
        .alert("Entropy Shield", isPresented: Binding(
            get: { incidentStore.lastError != nil || accomplishmentStore.lastError != nil || workGraphStore.lastError != nil },
            set: {
                if !$0 {
                    incidentStore.lastError = nil
                    accomplishmentStore.lastError = nil
                    workGraphStore.lastError = nil
                }
            }
        )) {
            Button("OK") {
                incidentStore.lastError = nil
                accomplishmentStore.lastError = nil
                workGraphStore.lastError = nil
            }
        }
        message: { Text(incidentStore.lastError ?? accomplishmentStore.lastError ?? workGraphStore.lastError ?? "") }
    }

    private var topBar: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 2) {
                Text(mode == .incidents ? "Incident Tracker" : "Accomplishment Tracker").font(.system(size: 23, weight: .bold))
                Text(mode == .incidents ? "Document Today. Defend Tomorrow." : "Document Today. Demonstrate Tomorrow.").font(.system(size: 13, weight: .medium)).foregroundStyle(ESTheme.muted)
            }.frame(width: 300, alignment: .leading)

            Picker("Mode", selection: $mode) {
                ForEach(TrackerMode.allCases) { item in Label(item.rawValue, systemImage: item.symbol).tag(item) }
            }.pickerStyle(.segmented).frame(width: 300)

            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass").foregroundStyle(ESTheme.muted)
                TextField(mode == .incidents ? "Search incidents..." : "Search accomplishments...", text: $searchText).textFieldStyle(.plain).font(.system(size: 14))
                if !searchText.isEmpty { Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill") }.buttonStyle(.plain).foregroundStyle(ESTheme.muted) }
            }
            .padding(.horizontal, 13).frame(maxWidth: 500, minHeight: 40).background(ESTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))

            Spacer()

            Menu {
                Button("Work Intelligence") { showingWorkIntelligence = true }
                Button("Relationship Work Graph") { showingWorkGraph = true }
                Divider()
                Button("Settings…") { openSettings() }
                Button("About Entropy Shield Work Record") { showingAbout = true }
                Divider()
                Button("Reveal Evidence Inbox") { AccomplishmentIntakeService.revealInbox() }
                Button("Scan Evidence Inbox Now") { _ = try? AccomplishmentIntakeService.scanInbox(store: accomplishmentStore) }
            } label: { Image(systemName: "ellipsis.circle").font(.system(size:18)) }
            .menuStyle(.borderlessButton).frame(width:32)

            Button {
                if mode == .incidents {
                    let record = incidentStore.createIncident(); incidentSelection = .all; selectedIncidentID = record.id
                } else {
                    let record = accomplishmentStore.createAccomplishment(); accomplishmentSelection = .all; selectedAccomplishmentID = record.id
                }
            } label: {
                Label(mode == .incidents ? "New Incident" : "New Accomplishment", systemImage: "plus").font(.system(size: 14, weight: .semibold)).padding(.horizontal, 8)
            }.buttonStyle(.borderedProminent).controlSize(.large).tint(ESTheme.accent).keyboardShortcut("n", modifiers: [.command])
        }
        .padding(.horizontal, 24).padding(.top, 18).padding(.bottom, 14).background(ESTheme.canvas)
    }

    private var incidentBody: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $incidentSelection).frame(width: 265)
            Divider().overlay(ESTheme.border)
            switch incidentSelection {
            case .timeline: TimelineView(searchText: searchText)
            case .reports: ReportsView(searchText: searchText)
            default:
                IncidentListView(incidents: filteredIncidents, selection: incidentSelection, selectedIncidentID: $selectedIncidentID, sort: $incidentSort).frame(width: 450)
                Divider().overlay(ESTheme.border)
                if let id = selectedIncidentID, let incident = incidentStore.incident(id: id) { IncidentEditorView(incident: incident).id(incident.id) }
                else { EmptyIncidentView() }
            }
        }
    }

    private var accomplishmentBody: some View {
        HStack(spacing: 0) {
            AccomplishmentSidebarView(selection: $accomplishmentSelection).frame(width: 265)
            Divider().overlay(ESTheme.border)
            if accomplishmentSelection == .reviewPrep {
                AccomplishmentReviewPrepView()
            } else if accomplishmentSelection == .insights {
                AccomplishmentInsightsView()
            } else if accomplishmentSelection == .intake {
                AccomplishmentIntakeView()
            } else {
                AccomplishmentListView(accomplishments: filteredAccomplishments, selection: accomplishmentSelection, selectedID: $selectedAccomplishmentID, sort: $accomplishmentSort).frame(width: 450)
                Divider().overlay(ESTheme.border)
                if let id = selectedAccomplishmentID, let record = accomplishmentStore.accomplishment(id: id) { AccomplishmentEditorView(accomplishment: record).id(record.id) }
                else { EmptyAccomplishmentView() }
            }
        }
    }

    private var incidentStatusBar: some View {
        HStack(spacing: 28) {
            StatusMetric(symbol: "doc.text", text: "\(incidentStore.totalCount) Total")
            StatusMetric(symbol: "calendar", text: "\(incidentStore.thisYearCount) This Year")
            StatusMetric(symbol: "pin", text: "\(incidentStore.pinnedCount) Pinned", gold: true)
            StatusMetric(symbol: "exclamationmark.circle", text: "\(incidentStore.openCount) Open")
            StatusMetric(symbol: "checkmark.circle", text: "\(incidentStore.resolvedCount) Resolved")
            StatusMetric(symbol: "sparkles", text: "\(incidentStore.aiEnrichedCount) AI Enriched", gold: true)
            StatusMetric(symbol: "link", text: "\(workGraphStore.links.count) Graph Links", gold: true)
            Spacer()
            Button { ExportService.exportReviewPacket(filteredIncidents, store: incidentStore) } label: { Label("Export Review Packet", systemImage: "doc.badge.arrow.up") }
                .buttonStyle(.borderedProminent).tint(ESTheme.accent)
        }.font(.system(size: 12, weight: .medium)).padding(.horizontal, 26).frame(height: 48).background(ESTheme.sidebar)
    }

    private var accomplishmentStatusBar: some View {
        HStack(spacing: 28) {
            StatusMetric(symbol: "trophy", text: "\(accomplishmentStore.totalCount) Total", gold: true)
            StatusMetric(symbol: "calendar", text: "\(accomplishmentStore.thisYearCount) This Year")
            StatusMetric(symbol: "pin", text: "\(accomplishmentStore.pinnedCount) Pinned", gold: true)
            StatusMetric(symbol: "checkmark.circle", text: "\(accomplishmentStore.completedCount) Completed")
            StatusMetric(symbol: "paperclip", text: "\(accomplishmentStore.evidenceCount) Evidence")
            StatusMetric(symbol: "sparkles", text: "\(accomplishmentStore.enrichedCount) Enriched", gold: true)
            StatusMetric(symbol: "link", text: "\(workGraphStore.links.count) Graph Links", gold: true)
            Spacer()
            Button { AccomplishmentExportService.exportReviewPacket(filteredAccomplishments, store: accomplishmentStore) } label: { Label("Export Accomplishment Review", systemImage: "doc.badge.arrow.up") }
                .buttonStyle(.borderedProminent).tint(ESTheme.accent)
        }.font(.system(size: 12, weight: .medium)).padding(.horizontal, 26).frame(height: 48).background(ESTheme.sidebar)
    }


    private func performAutomaticIntake() {
        if UserDefaults.standard.bool(forKey: "autoScanEvidenceInbox") { _ = try? AccomplishmentIntakeService.scanInbox(store: accomplishmentStore) }
        if appleMailAutoScan, !evidenceMailAccount.isEmpty, !evidenceMailPath.isEmpty {
            do { _ = try AppleMailWorkIntelligenceService.importEvidence(account: evidenceMailAccount, path: evidenceMailPath, store: accomplishmentStore) }
            catch { accomplishmentStore.lastError = "Automatic Mail evidence scan failed: \(error.localizedDescription)" }
        }
    }

    private func repairIncidentSelection() {
        guard incidentSelection != .timeline && incidentSelection != .reports else { return }
        let ids = Set(filteredIncidents.map(\.id)); if let id = selectedIncidentID, ids.contains(id) { return }; selectedIncidentID = filteredIncidents.first?.id
    }
    private func repairAccomplishmentSelection() {
        if accomplishmentSelection == .reviewPrep || accomplishmentSelection == .insights || accomplishmentSelection == .intake { return }
        let ids = Set(filteredAccomplishments.map(\.id)); if let id = selectedAccomplishmentID, ids.contains(id) { return }; selectedAccomplishmentID = filteredAccomplishments.first?.id
    }
}

private struct StatusMetric: View {
    let symbol: String; let text: String; var gold = false
    var body: some View { Label { Text(text) } icon: { Image(systemName: symbol).foregroundStyle(gold ? ESTheme.gold : ESTheme.accent) }.foregroundStyle(.white.opacity(0.82)) }
}

struct EmptyIncidentView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "exclamationmark.bubble").font(.system(size: 48, weight: .light)).foregroundStyle(ESTheme.gold)
            Text("No incident selected").font(.title2.bold())
            Text("Create an incident or choose one from the list. Keep the record factual, attach the evidence, and let future-you avoid reconstructing history from half-remembered email threads.").multilineTextAlignment(.center).foregroundStyle(ESTheme.muted).frame(maxWidth: 470)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(ESTheme.canvas)
    }
}

struct EmptyAccomplishmentView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "trophy").font(.system(size: 48, weight: .light)).foregroundStyle(ESTheme.gold)
            Text("No accomplishment selected").font(.title2.bold())
            Text("Create an accomplishment or choose one from the list. Capture the work, prove the impact, and spare future-you from having to remember six months of invisible labor during review season.").multilineTextAlignment(.center).foregroundStyle(ESTheme.muted).frame(maxWidth: 500)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(ESTheme.canvas)
    }
}
