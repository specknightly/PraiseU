import SwiftUI

struct IncidentAIView: View {
    @EnvironmentObject private var store: IncidentStore
    @Binding var draft: IncidentRecord
    @State private var isAnalyzing = false
    @State private var isNeutralizing = false
    @State private var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(ESTheme.gold)
                        Text("Incident AI")
                            .font(.system(size: 18, weight: .bold))
                    }
                    Text("On-device analysis for documentation quality, chronology, gaps, impact, follow-up, and pattern signals.")
                        .font(.system(size: 12))
                        .foregroundStyle(ESTheme.muted)
                    Text(LocalAIService.availabilityDescription())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ESTheme.gold)
                }
                Spacer()
            }
            .padding(15)
            .panelBackground()

            HStack(spacing: 10) {
                Button {
                    analyze()
                } label: {
                    if isAnalyzing {
                        ProgressView().controlSize(.small)
                        Text("Analyzing...")
                    } else {
                        Label("Analyze Incident", systemImage: "sparkles")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(ESTheme.accent)
                .disabled(isAnalyzing || isNeutralizing)

                Button {
                    neutralize()
                } label: {
                    if isNeutralizing {
                        ProgressView().controlSize(.small)
                        Text("Drafting...")
                    } else {
                        Label("Draft Neutral Facts", systemImage: "text.quote")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isAnalyzing || isNeutralizing)

                Spacer()
            }

            if let errorText {
                Label(errorText, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 12))
                    .foregroundStyle(ESTheme.gold)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ESTheme.gold.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 9))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("AI Analysis")
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Text("Non-evidentiary • verify before relying on it")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(ESTheme.muted)
                }
                TextEditor(text: $draft.aiAnalysis)
                    .font(.system(size: 13.5))
                    .scrollContentBackground(.hidden)
                    .padding(9)
                    .frame(minHeight: 330)
                    .background(ESTheme.field)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))
            }
            .padding(14)
            .panelBackground()

            if !draft.neutralFactsDraft.isEmpty {
                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Text("Neutral Facts Draft")
                            .font(.system(size: 14, weight: .bold))
                        Spacer()
                        Button("Apply to Observed Facts") {
                            draft.observedFacts = draft.neutralFactsDraft
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(ESTheme.accent)
                    }
                    Text("This is a proposed rewrite, not an automatic correction. Applying it requires an explicit click so the original meaning is never silently replaced.")
                        .font(.system(size: 11))
                        .foregroundStyle(ESTheme.muted)
                    TextEditor(text: $draft.neutralFactsDraft)
                        .font(.system(size: 13))
                        .scrollContentBackground(.hidden)
                        .padding(9)
                        .frame(minHeight: 180)
                        .background(ESTheme.field)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))
                }
                .padding(14)
                .panelBackground()
            }
        }
    }

    private func incidentForAI() -> IncidentRecord {
        var copy = draft
        if let live = store.incident(id: draft.id) {
            copy.evidence = live.evidence
        }
        return copy
    }

    private func analyze() {
        errorText = nil
        isAnalyzing = true
        Task {
            do {
                let result = try await LocalAIService.analyze(incidentForAI())
                await MainActor.run {
                    draft.aiAnalysis = result
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorText = error.localizedDescription
                    isAnalyzing = false
                }
            }
        }
    }

    private func neutralize() {
        errorText = nil
        isNeutralizing = true
        Task {
            do {
                let result = try await LocalAIService.neutralizeFacts(incidentForAI())
                await MainActor.run {
                    draft.neutralFactsDraft = result
                    isNeutralizing = false
                }
            } catch {
                await MainActor.run {
                    errorText = error.localizedDescription
                    isNeutralizing = false
                }
            }
        }
    }
}
