import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct WorkIntelligenceAssistantView: View {
    @EnvironmentObject private var incidentStore: IncidentStore
    @EnvironmentObject private var accomplishmentStore: AccomplishmentStore
    @EnvironmentObject private var workGraphStore: WorkGraphStore
    @EnvironmentObject private var preventionStore: PreventionLedgerStore
    @EnvironmentObject private var burdenStore: OperationalBurdenStore
    @EnvironmentObject private var driftStore: ResponsibilityDriftStore

    @AppStorage("roleTitle") private var roleTitle = ""
    @AppStorage("coreRoleDefinition") private var coreRoleDefinition = "Password resets, routine account access, basic desktop support, and other duties explicitly assigned to my primary IT support role."
    @AppStorage("expectedOtherPercent") private var expectedOtherPercent = 10.0

    let subject: WorkGraphNodeRef?

    @State private var question = ""
    @State private var previewSources: [WorkIntelligenceSource] = []
    @State private var selectedSourceIDs: Set<String> = []
    @State private var turns: [WorkIntelligenceTurn] = []
    @State private var isThinking = false
    @State private var error: String?

    init(subject: WorkGraphNodeRef? = nil) {
        self.subject = subject
    }

    private var subjectNode: WorkGraphCatalogNode? {
        guard let subject else { return nil }
        return WorkGraphCatalog.resolve(
            subject,
            incidents: incidentStore,
            accomplishments: accomplishmentStore,
            graph: workGraphStore
        )
    }

    private var selectedSources: [WorkIntelligenceSource] {
        previewSources.filter { selectedSourceIDs.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(ESTheme.border)

            HStack(spacing: 0) {
                conversationPane
                Divider().overlay(ESTheme.border)
                contextPane
            }

            Divider().overlay(ESTheme.border)
            composer
        }
        .frame(minWidth: 1120, minHeight: 760)
        .background(ESTheme.canvasGradient)
        .foregroundStyle(ESTheme.textPrimary)
        .onChange(of: question) { _, _ in
            previewSources = []
            selectedSourceIDs = []
            error = nil
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ESTheme.selection)
                    .frame(width: 46, height: 46)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ESTheme.borderStrong))
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(ESTheme.gold)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Work Intelligence Assistant")
                    .font(.system(size: 24, weight: .bold))
                if let subjectNode {
                    Text("Context anchored to \(subjectNode.kind.rawValue): \(subjectNode.title)")
                        .font(.callout)
                        .foregroundStyle(ESTheme.goldSoft)
                        .lineLimit(1)
                } else {
                    Text("Conversational analysis over your local evidence graph.")
                        .font(.callout)
                        .foregroundStyle(ESTheme.muted)
                }
            }

            Spacer()

            Label("On-device Apple Intelligence", systemImage: "lock.shield")
                .font(.caption)
                .foregroundStyle(ESTheme.muted)

            if !turns.isEmpty {
                Button("Export Transcript") { exportTranscript() }
                    .buttonStyle(.bordered)
                Button("Clear") {
                    turns = []
                    previewSources = []
                    selectedSourceIDs = []
                    error = nil
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
    }

    private var conversationPane: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if turns.isEmpty {
                    welcomePanel
                } else {
                    ForEach(turns) { turn in
                        turnCard(turn)
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var welcomePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ask the record, not a generic chatbot.")
                .font(.system(size: 21, weight: .bold))
            Text("Work Intelligence retrieves a bounded set of local records first. You can inspect and deselect those sources before anything is supplied to Apple Intelligence.")
                .font(.callout)
                .foregroundStyle(ESTheme.muted)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(WorkIntelligencePreset.defaults) { preset in
                    Button {
                        question = preset.prompt
                        prepareSources()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: preset.symbol)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(ESTheme.gold)
                            Text(preset.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(ESTheme.textPrimary)
                            Text(preset.prompt)
                                .font(.caption2)
                                .foregroundStyle(ESTheme.muted)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
                        .background(ESTheme.panelRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ESTheme.border))
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                Label("Evidence boundary", systemImage: "checkmark.shield")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ESTheme.gold)
                Text("Answers may interpret the selected records, but they cannot silently change them. Attachment metadata is visible to the assistant; attachment contents are not automatically read. Conversation history stays in memory unless you export it.")
                    .font(.caption)
                    .foregroundStyle(ESTheme.muted)
            }
            .padding(13)
            .panelBackground()
        }
        .padding(18)
        .panelBackground()
    }

    private func turnCard(_ turn: WorkIntelligenceTurn) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "person.crop.circle")
                    .foregroundStyle(ESTheme.goldSoft)
                Text(turn.question)
                    .font(.system(size: 14, weight: .semibold))
                    .textSelection(.enabled)
                Spacer()
                Text(turn.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(ESTheme.muted)
            }

            Divider().overlay(ESTheme.border)

            Text(turn.answer)
                .font(.system(size: 13))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !turn.sources.isEmpty {
                Divider().overlay(ESTheme.border)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Sources supplied for this answer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ESTheme.muted)

                    ForEach(Array(turn.sources.enumerated()), id: \.element.id) { index, source in
                        HStack(spacing: 7) {
                            Text("[S\(index + 1)]")
                                .font(.caption.monospaced().weight(.bold))
                                .foregroundStyle(ESTheme.gold)
                            Image(systemName: source.kind.symbol)
                                .foregroundStyle(ESTheme.goldSoft)
                                .frame(width: 16)
                            Text(source.title)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(source.kind.rawValue)
                                .font(.caption2)
                                .foregroundStyle(ESTheme.muted)
                        }
                    }
                }
            }
        }
        .padding(16)
        .panelBackground()
    }

    private var contextPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Context Inspector")
                        .font(.system(size: 15, weight: .bold))
                    Text("Only checked sources will be supplied.")
                        .font(.caption)
                        .foregroundStyle(ESTheme.muted)
                }
                Spacer()
                if !previewSources.isEmpty {
                    Text("\(selectedSources.count)/\(previewSources.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(ESTheme.gold)
                }
            }

            if previewSources.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "rectangle.stack.badge.magnifyingglass")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(ESTheme.gold)
                    Text("Preview the retrieval set before asking.")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Explicit graph links and current-record context receive the strongest ranking boost.")
                        .font(.caption)
                        .foregroundStyle(ESTheme.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack {
                    Button("All") {
                        selectedSourceIDs = Set(previewSources.map(\.id))
                    }
                    .buttonStyle(.bordered)
                    Button("None") { selectedSourceIDs = [] }
                        .buttonStyle(.bordered)
                    Spacer()
                }

                ScrollView {
                    LazyVStack(spacing: 9) {
                        ForEach(Array(previewSources.enumerated()), id: \.element.id) { index, source in
                            sourceCard(index: index, source: source)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 380)
        .background(ESTheme.sidebar)
    }

    private func sourceCard(index: Int, source: WorkIntelligenceSource) -> some View {
        Button {
            if selectedSourceIDs.contains(source.id) {
                selectedSourceIDs.remove(source.id)
            } else {
                selectedSourceIDs.insert(source.id)
            }
        } label: {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: selectedSourceIDs.contains(source.id) ? "checkmark.square.fill" : "square")
                    .foregroundStyle(selectedSourceIDs.contains(source.id) ? ESTheme.gold : ESTheme.muted)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("[S\(index + 1)]")
                            .font(.caption2.monospaced().weight(.bold))
                            .foregroundStyle(ESTheme.gold)
                        Text(source.kind.rawValue.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(ESTheme.muted)
                        Spacer()
                        Text(source.confidenceLabel.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(ESTheme.goldSoft)
                    }

                    Text(source.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ESTheme.textPrimary)
                        .lineLimit(2)

                    Text(source.subtitle)
                        .font(.caption2)
                        .foregroundStyle(ESTheme.muted)
                        .lineLimit(2)

                    if !source.reasons.isEmpty {
                        Text(source.reasons.prefix(2).joined(separator: " · "))
                            .font(.caption2)
                            .foregroundStyle(ESTheme.textPrimary.opacity(0.65))
                            .lineLimit(3)
                    }
                }
            }
            .padding(10)
            .background(selectedSourceIDs.contains(source.id) ? ESTheme.selection : ESTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedSourceIDs.contains(source.id) ? ESTheme.borderStrong : ESTheme.border)
            )
        }
        .buttonStyle(.plain)
    }

    private var composer: some View {
        VStack(spacing: 10) {
            if let error {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text(error)
                    Spacer()
                }
                .font(.caption)
                .foregroundStyle(ESTheme.gold)
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField(
                    subject == nil ? "Ask about your work record…" : "Ask about this record and its context…",
                    text: $question,
                    axis: .vertical
                )
                .lineLimit(2...5)
                .textFieldStyle(.plain)
                .padding(12)
                .background(ESTheme.field)
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(ESTheme.border))

                if previewSources.isEmpty {
                    Button {
                        prepareSources()
                    } label: {
                        Label("Preview Sources", systemImage: "rectangle.stack.badge.magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ESTheme.accent)
                    .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
                } else {
                    Button {
                        Task { await ask() }
                    } label: {
                        Label(isThinking ? "Thinking…" : "Ask with \(selectedSources.count)", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ESTheme.accent)
                    .disabled(isThinking || selectedSources.isEmpty || !AccomplishmentAIService.isAvailable)
                }
            }

            HStack {
                Text("Context is capped and source-selected before model use.")
                    .font(.caption2)
                    .foregroundStyle(ESTheme.muted)
                Spacer()
                if !AccomplishmentAIService.isAvailable {
                    Text("Apple Intelligence unavailable on this Mac.")
                        .font(.caption2)
                        .foregroundStyle(ESTheme.gold)
                }
            }
        }
        .padding(16)
        .background(ESTheme.sidebar)
    }

    private func prepareSources() {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return }

        let result = WorkIntelligenceRetrievalEngine.retrieve(
            question: trimmed,
            subject: subject,
            incidents: incidentStore,
            accomplishments: accomplishmentStore,
            prevention: preventionStore,
            burden: burdenStore,
            graph: workGraphStore,
            drift: driftStore,
            fallbackRoleTitle: roleTitle,
            fallbackRoleDefinition: coreRoleDefinition,
            fallbackExpectedAdjacentPercent: expectedOtherPercent,
            maxSources: 12
        )

        previewSources = result
        selectedSourceIDs = Set(result.map(\.id))
        error = result.isEmpty ? "No local records were relevant enough to build a context packet." : nil
    }

    @MainActor
    private func ask() async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3, !selectedSources.isEmpty, !isThinking else { return }

        let sources = selectedSources
        isThinking = true
        error = nil

        do {
            let answer = try await WorkIntelligenceAIService.answer(
                question: trimmed,
                sources: sources,
                priorTurns: turns
            )
            turns.append(WorkIntelligenceTurn(
                question: trimmed,
                answer: answer,
                sources: sources
            ))
            question = ""
            previewSources = []
            selectedSourceIDs = []
        } catch {
            self.error = error.localizedDescription
        }

        isThinking = false
    }

    private func exportTranscript() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "Work-Intelligence-Transcript.md"
        panel.title = "Export Work Intelligence Transcript"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        var output = "# Work Intelligence Assistant Transcript\n\n"
        output += "Generated: \(Date().formatted(date: .long, time: .shortened))\n\n"
        output += "> Generated analysis is non-evidentiary. Verify claims against the cited local source records.\n\n"

        for turn in turns {
            output += "## Question\n\n\(turn.question)\n\n"
            output += "## Answer\n\n\(turn.answer)\n\n"
            output += "### Sources supplied\n\n"
            for (index, source) in turn.sources.enumerated() {
                output += "- [S\(index + 1)] \(source.kind.rawValue): \(source.title)"
                if let date = source.date {
                    output += " — \(date.formatted(date: .abbreviated, time: .omitted))"
                }
                output += "\n"
            }
            output += "\n---\n\n"
        }

        do {
            try output.data(using: .utf8)?.write(to: url, options: .atomic)
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}
