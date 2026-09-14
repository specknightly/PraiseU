import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AppKit

struct EntryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var entry: Accomplishment

    @State private var importingFiles = false
    @State private var importError: String?
    @State private var enrichmentError: String?
    @State private var isEnriching = false
    @State private var isInferringScope = false
    @State private var isAnalyzingEvidence = false
    @State private var isAnalyzingProfessional = false
    @AppStorage("coreRoleDefinition") private var coreRoleDefinition = "Password resets, routine account access, basic desktop support, and other duties explicitly assigned to my primary IT support role."

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                Divider()
                evidenceFramework
                humanValueSection
                scopeIntelligenceSection
                professionalIntelligenceSection
                attachmentSection
                metadataSection
            }
            .padding(28)
            .frame(maxWidth: 900, alignment: .leading)
        }
        .navigationTitle(entry.title.isEmpty ? "Accomplishment" : entry.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    entry.isPinned.toggle()
                    touch()
                } label: {
                    Label(entry.isPinned ? "Unpin" : "Pin", systemImage: entry.isPinned ? "pin.fill" : "pin")
                }
            }
        }
        .fileImporter(
            isPresented: $importingFiles,
            allowedContentTypes: [.data],
            allowsMultipleSelection: true,
            onCompletion: handleImport
        )
        .alert("Could Not Import Evidence", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "Unknown import error")
        }
        .alert("Apple Intelligence Analysis Failed", isPresented: Binding(
            get: { enrichmentError != nil },
            set: { if !$0 { enrichmentError = nil } }
        )) {
            Button("OK", role: .cancel) { enrichmentError = nil }
        } message: {
            Text(enrichmentError ?? "Unknown Apple Intelligence error")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Accomplishment title", text: $entry.title)
                .font(.largeTitle.weight(.bold))
                .textFieldStyle(.plain)
                .onChange(of: entry.title) { _, _ in touch() }

            HStack(spacing: 12) {
                DatePicker("Date", selection: $entry.date, displayedComponents: .date)
                    .labelsHidden()
                    .onChange(of: entry.date) { _, _ in touch() }

                Picker("Category", selection: Binding(
                    get: { entry.category },
                    set: { entry.category = $0; touch() }
                )) {
                    ForEach(AccomplishmentCategory.allCases) { category in
                        Label(category.rawValue, systemImage: category.symbol).tag(category)
                    }
                }
                .frame(maxWidth: 240)

                Spacer()

                Text("Updated \(entry.updatedAt, format: .relative(presentation: .named))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var evidenceFramework: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeading(
                "Evidence Framework",
                subtitle: "Capture enough detail that someone who was not there can understand what happened and why it mattered."
            )

            EditorField(
                title: "1. Situation / Context",
                prompt: "What problem, request, risk, outage, project need, or opportunity existed?",
                text: $entry.context,
                minHeight: 95,
                onChange: touch
            )

            EditorField(
                title: "2. What I Did",
                prompt: "Describe your specific actions, decisions, troubleshooting, coordination, or implementation work.",
                text: $entry.actionTaken,
                minHeight: 120,
                onChange: touch
            )

            EditorField(
                title: "3. Outcome",
                prompt: "What changed because of your work? What was restored, delivered, prevented, improved, or completed?",
                text: $entry.outcome,
                minHeight: 100,
                onChange: touch
            )

            EditorField(
                title: "4. Organizational Impact",
                prompt: "Why did this matter to the department or organization? Consider reliability, security, user experience, risk, time, cost, or service quality.",
                text: $entry.businessImpact,
                minHeight: 100,
                onChange: touch
            )

            EditorField(
                title: "5. Metrics / Quantifiable Evidence",
                prompt: "Examples: users affected, hours saved, incidents reduced, uptime restored, devices migrated, tickets avoided, dollars saved.",
                text: $entry.metrics,
                minHeight: 85,
                onChange: touch
            )

            EditorField(
                title: "6. Supporting Evidence Notes",
                prompt: "Record ticket numbers, project names, email threads, change records, meeting names, screenshots, or other corroborating evidence.",
                text: $entry.evidenceNotes,
                minHeight: 95,
                onChange: touch
            )
        }
    }

    private var humanValueSection: some View {
        let availability = AppleIntelligenceEnrichmentService.availability
        let analysisBinding = Binding<String>(
            get: { entry.humanValueAnalysis ?? "" },
            set: { newValue in
                entry.humanValueAnalysis = newValue.isEmpty ? nil : newValue
            }
        )

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                sectionHeading(
                    "Human Value Analysis",
                    subtitle: "Use Apple Intelligence on-device to explain where your judgment, accountability, context, communication, or hands-on work added value beyond AI alone."
                )

                Spacer(minLength: 20)

                Button {
                    Task { await enrichHumanValue() }
                } label: {
                    if isEnriching {
                        Label("Analyzing…", systemImage: "sparkles")
                    } else {
                        Label(entry.humanValueAnalysis == nil ? "Analyze Human Value" : "Reanalyze", systemImage: "sparkles")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isEnriching || !hasEnoughEnrichmentDetail)
            }

            HStack(spacing: 8) {
                Image(systemName: availability.isAvailable ? "checkmark.circle.fill" : "info.circle")
                Text(availability.message)
                if let generatedAt = entry.humanValueGeneratedAt {
                    Text("• Last generated \(generatedAt, format: .relative(presentation: .named))")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if isEnriching {
                ProgressView()
                    .progressViewStyle(.linear)
            }

            EditorField(
                title: "7. Why Human Judgment Mattered",
                prompt: "Generated locally when you use the button above. Edit the result freely before using it in a review packet.",
                text: analysisBinding,
                minHeight: 150,
                onChange: touch
            )

            if entry.humanValueAnalysis != nil {
                HStack {
                    Spacer()
                    Button("Clear AI Analysis", role: .destructive) {
                        entry.humanValueAnalysis = nil
                        entry.humanValueGeneratedAt = nil
                        touch()
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(18)
        .background(.quaternary.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary, lineWidth: 1)
        }
    }

    private var hasEnoughEnrichmentDetail: Bool {
        enrichmentInput.hasEnoughDetail
    }

    private var enrichmentInput: AccomplishmentEnrichmentInput {
        AccomplishmentEnrichmentInput(
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
    }

    @MainActor
    private func enrichHumanValue() async {
        guard !isEnriching else { return }
        isEnriching = true
        enrichmentError = nil
        let input = enrichmentInput

        defer { isEnriching = false }

        do {
            let analysis = try await AppleIntelligenceEnrichmentService.analyze(input)
            entry.humanValueAnalysis = analysis
            entry.humanValueGeneratedAt = .now
            touch()
        } catch {
            enrichmentError = error.localizedDescription
        }
    }

    private var scopeIntelligenceSection: some View {
        let analysisBinding = Binding<String>(
            get: { entry.scopeInference ?? "" },
            set: { entry.scopeInference = $0.isEmpty ? nil : $0 }
        )
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                sectionHeading("Scope Drift Intelligence", subtitle: "Compare this work with your role baseline and preserve evidence when your actual responsibilities expand beyond the job on paper.")
                Spacer()
                Picker("Scope", selection: Binding(get: { entry.responsibilityScope }, set: { entry.responsibilityScope = $0; touch() })) {
                    ForEach(ResponsibilityScope.allCases) { scope in
                        Label(scope.rawValue, systemImage: scope.symbol).tag(scope)
                    }
                }.frame(width: 210)
            }

            HStack {
                Button {
                    Task { await inferScope() }
                } label: {
                    if isInferringScope { ProgressView().controlSize(.small) } else { Label("Infer Scope & Career Signal", systemImage: "scope") }
                }
                .disabled(isInferringScope || !AppleIntelligenceEnrichmentService.availability.isAvailable || !hasEnoughEnrichmentDetail)
                Text("Baseline is editable in Settings.").font(.caption).foregroundStyle(.secondary)
            }

            if !analysisBinding.wrappedValue.isEmpty {
                TextEditor(text: analysisBinding)
                    .font(.body)
                    .frame(minHeight: 180)
                    .padding(8)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
                    .onChange(of: analysisBinding.wrappedValue) { _, _ in touch() }
            } else {
                Text("No scope inference yet. Run the local analysis after documenting enough context and action detail.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
    }

    @MainActor
    private func inferScope() async {
        guard !isInferringScope else { return }
        isInferringScope = true
        enrichmentError = nil
        defer { isInferringScope = false }
        do {
            let result = try await AppleIntelligenceEnrichmentService.inferScope(enrichmentInput, coreRoleDefinition: coreRoleDefinition)
            entry.responsibilityScope = result.scope
            entry.scopeInference = result.analysis
            entry.scopeInferenceGeneratedAt = .now
            touch()
        } catch {
            enrichmentError = error.localizedDescription
        }
    }

    private var professionalIntelligenceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                sectionHeading("Professional Intelligence", subtitle: "Build a skeptical, evidence-grounded interpretation of claim strength, work level, scope drift, capabilities, organizational reach, and missing proof.")
                Spacer()
                if let score = entry.claimStrength {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(score)/100").font(.title2.weight(.bold)).monospacedDigit()
                        Text("Claim strength").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    Task { await analyzeEvidence() }
                } label: {
                    if isAnalyzingEvidence { ProgressView().controlSize(.small) } else { Label("Analyze Attached Evidence", systemImage: "doc.text.magnifyingglass") }
                }
                .disabled(isAnalyzingEvidence || entry.attachments.isEmpty || !AppleIntelligenceEnrichmentService.availability.isAvailable)

                Button {
                    Task { await analyzeProfessionalIntelligence() }
                } label: {
                    if isAnalyzingProfessional { ProgressView().controlSize(.small) } else { Label("Build Professional Intelligence", systemImage: "brain.head.profile") }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAnalyzingProfessional || !hasEnoughEnrichmentDetail || !AppleIntelligenceEnrichmentService.availability.isAvailable)

                Picker("Work Level", selection: Binding(get: { entry.workLevel }, set: { entry.workLevel = $0; touch() })) {
                    ForEach(WorkLevel.allCases) { level in Label(level.rawValue, systemImage: level.symbol).tag(level) }
                }.frame(width: 210)
            }

            if let evidence = entry.evidenceAnalysis, !evidence.isEmpty {
                DisclosureGroup("Evidence Analysis") {
                    Text(evidence).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
                }
            }

            if let intelligence = entry.professionalIntelligence, !intelligence.isEmpty {
                TextEditor(text: Binding(get: { intelligence }, set: { entry.professionalIntelligence = $0; touch() }))
                    .font(.body)
                    .frame(minHeight: 260)
                    .padding(8)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
            } else {
                Text("No professional intelligence generated yet. The analysis deliberately challenges weak claims instead of automatically agreeing with them.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.quaternary.opacity(0.22), in: RoundedRectangle(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).stroke(.quaternary, lineWidth: 1) }
    }

    @MainActor
    private func analyzeEvidence() async {
        guard !isAnalyzingEvidence else { return }
        isAnalyzingEvidence = true
        enrichmentError = nil
        defer { isAnalyzingEvidence = false }
        let input = EvidenceAnalysisInput(
            title: entry.title,
            outcome: entry.outcome,
            businessImpact: entry.businessImpact,
            attachments: entry.attachments.map {
                EvidenceAttachmentInput(originalFilename: $0.originalFilename, relativePath: $0.relativePath)
            }
        )
        do {
            entry.evidenceAnalysis = try await EvidenceIntelligenceService.analyzeEvidence(input: input)
            entry.evidenceAnalysisGeneratedAt = .now
            touch()
        } catch { enrichmentError = error.localizedDescription }
    }

    @MainActor
    private func analyzeProfessionalIntelligence() async {
        guard !isAnalyzingProfessional else { return }
        isAnalyzingProfessional = true
        enrichmentError = nil
        defer { isAnalyzingProfessional = false }
        let input = ProfessionalIntelligenceInput(
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
        do {
            let result = try await EvidenceIntelligenceService.professionalIntelligence(input: input, coreRoleDefinition: coreRoleDefinition)
            entry.claimStrength = result.claimStrength
            entry.workLevel = result.workLevel
            entry.professionalIntelligence = result.analysis
            entry.professionalIntelligenceGeneratedAt = .now
            touch()
        } catch { enrichmentError = error.localizedDescription }
    }

    private var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeading("Evidence Files", subtitle: "Files are copied into this Mac's local app data. The originals are not modified.")
                Spacer()
                Button {
                    importingFiles = true
                } label: {
                    Label("Attach Files", systemImage: "paperclip")
                }
            }

            if entry.attachments.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "doc.badge.plus")
                    Text("No files attached. Add screenshots, exported tickets, PDFs, change records, or other evidence when useful.")
                }
                .foregroundStyle(.secondary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.attachments.sorted(by: { $0.addedAt > $1.addedAt }), id: \.id) { attachment in
                        AttachmentRow(attachment: attachment) {
                            open(attachment)
                        } onDelete: {
                            delete(attachment)
                        }
                    }
                }
            }
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading("Indexing", subtitle: "These fields make the archive easier to search when review season arrives with its traditional lack of warning.")

            LabeledContent("Stakeholders") {
                TextField("Teams, departments, users, managers, vendors…", text: $entry.stakeholders)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: entry.stakeholders) { _, _ in touch() }
            }

            LabeledContent("Tags") {
                TextField("Comma-separated: migration, outage, automation, executive-support", text: $entry.tagsText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: entry.tagsText) { _, _ in touch() }
            }
        }
        .padding(.bottom, 28)
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title3.weight(.semibold))
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private func touch() {
        entry.updatedAt = .now
        try? modelContext.save()
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            let imported = try AttachmentStore.importFiles(urls, for: entry.id)
            for file in imported {
                let attachment = EvidenceAttachment(
                    originalFilename: file.originalFilename,
                    relativePath: file.relativePath,
                    byteCount: file.byteCount
                )
                modelContext.insert(attachment)
                entry.attachments.append(attachment)
            }
            touch()
        } catch {
            importError = error.localizedDescription
        }
    }

    private func open(_ attachment: EvidenceAttachment) {
        guard let url = AttachmentStore.url(for: attachment.relativePath) else { return }
        NSWorkspace.shared.open(url)
    }

    private func delete(_ attachment: EvidenceAttachment) {
        AttachmentStore.delete(relativePath: attachment.relativePath)
        if let index = entry.attachments.firstIndex(where: { $0.id == attachment.id }) {
            entry.attachments.remove(at: index)
        }
        modelContext.delete(attachment)
        touch()
    }
}

private struct EditorField: View {
    let title: String
    let prompt: String
    @Binding var text: String
    let minHeight: CGFloat
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.headline)
            Text(prompt).font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(9)
                .frame(minHeight: minHeight)
                .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.quaternary, lineWidth: 1)
                }
                .onChange(of: text) { _, _ in onChange() }
        }
    }
}

private struct AttachmentRow: View {
    let attachment: EvidenceAttachment
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc")
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.originalFilename).lineLimit(1)
                Text(ByteCountFormatter.string(fromByteCount: attachment.byteCount, countStyle: .file))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Open", action: onOpen)
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
    }
}
