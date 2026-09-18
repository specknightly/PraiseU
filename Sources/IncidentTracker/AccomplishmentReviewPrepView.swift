import SwiftUI

struct AccomplishmentReviewPrepView: View {
    @EnvironmentObject private var store: AccomplishmentStore
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var analysis = ""
    @State private var isRunning = false
    @State private var error: String?
    @State private var outputTitle = ""
    @AppStorage("expectedOtherPercent") private var expectedOtherPercent = 10.0
    @AppStorage("coreRoleDefinition") private var roleBaseline = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Performance Review Prep").font(.system(size: 24, weight: .bold))
                        Text("Stress-test the raise or promotion case before your supervisor does.").foregroundStyle(ESTheme.muted)
                    }
                    Spacer()
                    Stepper("Year: \(year)", value: $year, in: 2020...2100).frame(width: 150)
                    Menu {
                        Button("Challenge My Raise Case") { Task { await challenge() } }
                        Button("Generate Brag Document") { Task { await brag() } }
                        Button("Generate Professional Value Model") { Task { await valueModel() } }
                    } label: { Label(isRunning ? "Analyzing…" : "Generate Review Intelligence", systemImage: "sparkles") }
                        .buttonStyle(.borderedProminent).tint(ESTheme.gold).disabled(isRunning || !AccomplishmentAIService.isAvailable)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Role Baseline").font(.headline)
                    TextEditor(text: $roleBaseline).frame(minHeight: 90).padding(8).background(ESTheme.field).clipShape(RoundedRectangle(cornerRadius: 9)).overlay(RoundedRectangle(cornerRadius: 9).stroke(ESTheme.border))
                    Text("This is the baseline the AI uses when testing the argument that your accomplishments were simply normal job duties.").font(.caption).foregroundStyle(ESTheme.muted)
                }.padding(14).panelBackground()
                if let error { Text(error).foregroundStyle(.red) }
                if isRunning { ProgressView().progressViewStyle(.linear) }
                if !outputTitle.isEmpty { Text(outputTitle).font(.title2.bold()).foregroundStyle(ESTheme.gold) }
                if analysis.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "shield.lefthalf.filled").font(.system(size: 44)).foregroundStyle(ESTheme.gold)
                        Text("Adversarial review preparation").font(.title3.bold())
                        Text("Apple Intelligence will build the strongest fair counterargument against your raise or promotion case, expose weak evidence, and prepare factual responses. It is intentionally not a cheerleader.").multilineTextAlignment(.center).foregroundStyle(ESTheme.muted).frame(maxWidth: 620)
                    }.frame(maxWidth: .infinity).padding(.vertical, 70)
                } else {
                    TextEditor(text: $analysis).font(.system(size: 14)).scrollContentBackground(.hidden).padding(12).frame(minHeight: 560).background(ESTheme.field).clipShape(RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(ESTheme.border))
                }
            }.padding(24)
        }.background(ESTheme.canvas)
    }

    @MainActor private func challenge() async {
        guard !isRunning else { return }; isRunning = true; error = nil; defer { isRunning = false }
        do { outputTitle = "Challenge My Raise Case"; analysis = try await AccomplishmentAIService.challengeRaiseCase(store.accomplishments, year: year, roleBaseline: roleBaseline) }
        catch { self.error = error.localizedDescription }
    }

    @MainActor private func brag() async {
        guard !isRunning else { return }; isRunning = true; error = nil; defer { isRunning = false }
        do { outputTitle = "Brag Document"; analysis = try await AccomplishmentAIService.bragDocument(store.accomplishments, year: year, roleBaseline: roleBaseline) }
        catch { self.error = error.localizedDescription }
    }
    @MainActor private func valueModel() async {
        guard !isRunning else { return }; isRunning = true; error = nil; defer { isRunning = false }
        do { outputTitle = "Professional Value Model"; analysis = try await AccomplishmentAIService.professionalValueModel(store.accomplishments, year: year, roleBaseline: roleBaseline, expectedOtherPercent: Int(expectedOtherPercent)) }
        catch { self.error = error.localizedDescription }
    }
}
