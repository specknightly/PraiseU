import SwiftUI

struct AccomplishmentEditorView: View {
    @EnvironmentObject private var store: AccomplishmentStore
    let accomplishment: AccomplishmentRecord
    @State private var draft: AccomplishmentRecord
    @State private var tab: AccomplishmentDetailTab = .details
    @State private var showDeleteConfirmation = false
    @State private var isRunningAI = false
    @State private var aiError: String?

    init(accomplishment: AccomplishmentRecord) {
        self.accomplishment = accomplishment
        _draft = State(initialValue: accomplishment)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    metadata
                    tabs
                    switch tab {
                    case .details: detailsTab
                    case .evidence: AccomplishmentEvidenceView(accomplishmentID: draft.id)
                    case .intelligence: intelligenceTab
                    case .recall: ContextualRecallView(subject: WorkGraphNodeRef(kind: .accomplishment, nodeID: draft.id))
                    case .prevention: PreventionLedgerView(subject: WorkGraphNodeRef(kind: .accomplishment, nodeID: draft.id)).frame(minHeight: 560)
                    case .relationships: RelationshipEditorView(subject: WorkGraphNodeRef(kind: .accomplishment, nodeID: draft.id))
                    case .notes: notesTab
                    }
                }.padding(22)
            }
            Divider().overlay(ESTheme.border)
            footer
        }
        .background(ESTheme.canvas)
        .confirmationDialog("Delete this accomplishment?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Accomplishment", role: .destructive) { store.delete(draft.id) }
            Button("Cancel", role: .cancel) {}
        } message: { Text("The accomplishment record and its copied evidence files will be removed.") }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: draft.category.symbol).font(.system(size: 30, weight: .semibold)).foregroundStyle(ESTheme.gold).frame(width: 44, height: 44)
            TextField("Accomplishment title", text: $draft.title, axis: .vertical).textFieldStyle(.plain).font(.system(size: 22, weight: .bold)).lineLimit(1...3)
            Spacer(minLength: 20)
            Button { AccomplishmentExportService.export(draft, store: store) } label: { Label("Export Accomplishment", systemImage: "doc.badge.arrow.up") }.buttonStyle(.bordered)
        }
    }

    private var metadata: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                AccomplishmentMetadataBox(title: "Date") { DatePicker("", selection: $draft.date).labelsHidden() }
                AccomplishmentMetadataBox(title: "Category") {
                    Picker("", selection: $draft.category) { ForEach(AccomplishmentCategory.allCases) { Text($0.rawValue).tag($0) } }.labelsHidden()
                }
                AccomplishmentMetadataBox(title: "State") {
                    Picker("", selection: $draft.isDraft) { Text("Draft").tag(true); Text("Completed").tag(false) }.labelsHidden()
                }
                Toggle("Pin", isOn: $draft.isPinned).toggleStyle(.checkbox).frame(width: 75, alignment: .leading)
            }
            HStack(spacing: 12) {
                AccomplishmentMetadataBox(title: "Tags (comma separated)") { TextField("Infrastructure, Project, Leadership", text: $draft.tagsText).textFieldStyle(.plain) }
                AccomplishmentMetadataBox(title: "Stakeholders") { TextField("Faculty, staff, team, department", text: $draft.stakeholders).textFieldStyle(.plain) }
            }
        }
    }

    private var tabs: some View {
        HStack(spacing: 25) {
            ForEach(AccomplishmentDetailTab.allCases) { item in
                Button { tab = item } label: {
                    HStack(spacing: 7) { Image(systemName: item.symbol); Text(item == .evidence ? "Evidence (\(draft.evidence.count))" : item.rawValue) }
                        .font(.system(size: 13, weight: tab == item ? .semibold : .medium)).foregroundStyle(tab == item ? ESTheme.accent : .white.opacity(0.82))
                        .padding(.bottom, 8).overlay(alignment: .bottom) { Rectangle().fill(tab == item ? ESTheme.accent : Color.clear).frame(height: 2) }
                }.buttonStyle(.plain)
            }
            Spacer()
        }.padding(.top, 4)
    }

    private var detailsTab: some View {
        VStack(spacing: 14) {
            accomplishmentIntegrityBanner
            AccomplishmentTextArea(title: "Context / Challenge", help: "What situation, request, problem, or opportunity existed before your work?", text: $draft.context, minHeight: 105)
            AccomplishmentTextArea(title: "Action Taken / What I Did", help: "Document the judgment, troubleshooting, coordination, design, implementation, or ownership you personally contributed.", text: $draft.actionTaken, minHeight: 125)
            AccomplishmentTextArea(title: "Outcome", help: "What changed because of the work? Keep this concrete and attributable.", text: $draft.outcome, minHeight: 100)
            AccomplishmentTextArea(title: "Business / Operational Impact", help: "Time saved, risk reduced, service restored, users helped, cost avoided, reliability improved, or capability created.", text: $draft.businessImpact, minHeight: 105)
            HStack(alignment: .top, spacing: 14) {
                AccomplishmentTextArea(title: "Metrics", help: "Numbers, scale, duration, volume, savings, response time, or other measurable support.", text: $draft.metrics, minHeight: 85)
                AccomplishmentTextArea(title: "Evidence Notes", help: "Describe evidence that exists even if it is not attached yet.", text: $draft.evidenceNotes, minHeight: 85)
            }
        }
    }

    private var intelligenceTab: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Button { Task { await runHumanValue() } } label: { Label(isRunningAI ? "Analyzing…" : "Analyze Human Value", systemImage: "sparkles") }
                    .buttonStyle(.borderedProminent).tint(ESTheme.accent).disabled(isRunningAI || !AccomplishmentAIService.isAvailable)
                Button { Task { await runProfessionalIntelligence() } } label: { Label("Build Professional Intelligence", systemImage: "brain.head.profile") }
                    .buttonStyle(.bordered).disabled(isRunningAI || !AccomplishmentAIService.isAvailable)
                Button { Task { await runEvidenceAnalysis() } } label: { Label("Analyze Evidence", systemImage: "doc.text.magnifyingglass") }
                    .buttonStyle(.bordered).disabled(isRunningAI || draft.evidence.isEmpty || !AccomplishmentAIService.isAvailable)
                Spacer()
                Text(AccomplishmentAIService.isAvailable ? "Apple Intelligence ready · on-device" : "Apple Intelligence unavailable")
                    .font(.system(size: 11)).foregroundStyle(ESTheme.muted)
            }
            if let aiError { Text(aiError).font(.system(size: 11, weight: .medium)).foregroundStyle(.red) }

            HStack(spacing: 12) {
                AccomplishmentMetadataBox(title: "Responsibility Scope") {
                    Picker("", selection: $draft.responsibilityScope) { ForEach(ResponsibilityScope.allCases) { Text($0.rawValue).tag($0) } }.labelsHidden()
                }
                AccomplishmentMetadataBox(title: "Work Level") {
                    Picker("", selection: $draft.workLevel) { ForEach(WorkLevel.allCases) { Text($0.rawValue).tag($0) } }.labelsHidden()
                }
                AccomplishmentMetadataBox(title: "Claim Strength (0-100)") {
                    TextField("0", value: $draft.claimStrength, format: .number).textFieldStyle(.plain)
                }
            }
            AccomplishmentTextArea(title: "Why Human Judgment Mattered", help: "Capture why your context, judgment, communication, trust, physical presence, or cross-system reasoning mattered.", text: $draft.humanValueAnalysis, minHeight: 120)
            AccomplishmentTextArea(title: "Scope Inference", help: "Why this belongs inside your core role or represents scope drift / higher-level work.", text: $draft.scopeInference, minHeight: 100)
            AccomplishmentTextArea(title: "Professional Intelligence", help: "Patterns, leadership signals, specialist work, ownership, leverage, or recurring value demonstrated by this accomplishment.", text: $draft.professionalIntelligence, minHeight: 120)
            AccomplishmentTextArea(title: "Evidence Analysis", help: "What the attached evidence supports, and what it does not prove.", text: $draft.evidenceAnalysis, minHeight: 100)
        }
    }

    @MainActor private func runHumanValue() async {
        guard !isRunningAI else { return }; isRunningAI = true; aiError = nil; defer { isRunningAI = false }
        do { draft.humanValueAnalysis = try await AccomplishmentAIService.humanValue(draft); store.save(draft) }
        catch { aiError = error.localizedDescription }
    }

    @MainActor private func runProfessionalIntelligence() async {
        guard !isRunningAI else { return }; isRunningAI = true; aiError = nil; defer { isRunningAI = false }
        do {
            let text = try await AccomplishmentAIService.professionalIntelligence(draft, roleBaseline: UserDefaults.standard.string(forKey: "coreRoleDefinition") ?? "")
            draft.professionalIntelligence = text
            let lines = text.components(separatedBy: .newlines)
            if let l = lines.first(where: { $0.uppercased().contains("CLAIM_STRENGTH") }), let n = Int(l.components(separatedBy: ":").last?.trimmingCharacters(in: CharacterSet(charactersIn: " *#")) ?? "") { draft.claimStrength = max(0, min(100, n)) }
            if let l = lines.first(where: { $0.uppercased().contains("WORK_LEVEL") })?.uppercased() {
                if l.contains("STRATEGIC") { draft.workLevel = .strategic } else if l.contains("PROJECT_OWNER") { draft.workLevel = .projectOwner } else if l.contains("SPECIALIST") { draft.workLevel = .specialist } else if l.contains("ADVANCED") { draft.workLevel = .advanced } else { draft.workLevel = .routine }
            }
            store.save(draft)
        } catch { aiError = error.localizedDescription }
    }

    @MainActor private func runEvidenceAnalysis() async {
        guard !isRunningAI else { return }; isRunningAI=true; aiError=nil; defer { isRunningAI=false }
        do { draft.evidenceAnalysis = try await AccomplishmentEvidenceIntelligenceService.analyze(draft, store: store); store.save(draft) }
        catch { aiError=error.localizedDescription }
    }

    private var notesTab: some View {
        AccomplishmentTextArea(title: "Working Notes", help: "Use this for supporting context or details that do not fit the formal accomplishment narrative.", text: $draft.evidenceNotes, minHeight: 430)
    }

    private var accomplishmentIntegrityBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: draft.completeness >= 0.8 ? "checkmark.shield.fill" : "exclamationmark.triangle.fill").foregroundStyle(draft.completeness >= 0.8 ? ESTheme.accent : ESTheme.gold)
            VStack(alignment: .leading, spacing: 3) {
                Text("Record completeness: \(Int(draft.completeness * 100))%").font(.system(size: 13, weight: .semibold))
                Text(draft.completeness >= 0.8 ? "Strong enough to be useful later." : "Add context, action, outcome, impact, and evidence so this does not become a heroic but unverifiable anecdote.")
                    .font(.system(size: 11)).foregroundStyle(ESTheme.muted)
            }
            Spacer()
        }.padding(12).background(ESTheme.panelRaised).clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private var footer: some View {
        HStack {
            Image(systemName: "clock").foregroundStyle(ESTheme.muted)
            Text("Last modified: \(draft.modifiedAt.formatted(date: .abbreviated, time: .shortened))").foregroundStyle(ESTheme.muted).font(.system(size: 12))
            Spacer()
            Button(role: .destructive) { showDeleteConfirmation = true } label: { Label("Delete", systemImage: "trash") }.buttonStyle(.bordered)
            Button("Revert") { if let latest = store.accomplishment(id: draft.id) { draft = latest } }.buttonStyle(.bordered)
            Button("Save Changes") { store.save(draft); if let saved = store.accomplishment(id: draft.id) { draft = saved } }.buttonStyle(.borderedProminent).tint(ESTheme.accent).keyboardShortcut("s", modifiers: [.command])
        }.padding(.horizontal, 22).frame(height: 58).background(ESTheme.sidebar)
    }
}

private struct AccomplishmentMetadataBox<Content: View>: View {
    let title: String; let content: Content
    init(title: String, @ViewBuilder content: () -> Content) { self.title = title; self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) { Text(title.uppercased()).font(.system(size: 9, weight: .bold)).foregroundStyle(ESTheme.muted); content }
            .padding(.horizontal, 12).padding(.vertical, 9).frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(ESTheme.field).clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))
    }
}

private struct AccomplishmentTextArea: View {
    let title: String; let help: String; @Binding var text: String; let minHeight: CGFloat
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(size: 13, weight: .semibold)); Text(help).font(.system(size: 11)).foregroundStyle(ESTheme.muted)
            TextEditor(text: $text).font(.system(size: 14)).scrollContentBackground(.hidden).padding(8).frame(minHeight: minHeight)
                .background(ESTheme.field).clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))
        }.padding(14).panelBackground()
    }
}
