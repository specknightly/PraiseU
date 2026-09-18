import SwiftUI

struct UnifiedWorkIntelligenceView: View {
    @EnvironmentObject private var incidentStore: IncidentStore
    @EnvironmentObject private var accomplishmentStore: AccomplishmentStore
    @State private var year=Calendar.current.component(.year,from:Date())
    @State private var report=""
    @State private var running=false
    @State private var error:String?

    var body: some View {
        VStack(spacing:0) {
            HStack {
                VStack(alignment:.leading,spacing:4) {
                    Text("Work Intelligence").font(.system(size:26,weight:.bold))
                    Text("Analyze accomplishments and incidents as one evidence system.").foregroundStyle(ESTheme.muted)
                }
                Spacer(); Stepper("Year: \(year)",value:$year,in:2020...2100).frame(width:150)
                Button { Task { await run() } } label:{Label(running ? "Analyzing…":"Analyze Both Sides",systemImage:"arrow.triangle.branch")}.buttonStyle(.borderedProminent).tint(ESTheme.gold).disabled(running || !AccomplishmentAIService.isAvailable)
            }.padding(22)
            Divider().overlay(ESTheme.border)
            if let error { Text(error).foregroundStyle(.red).padding() }
            if running { ProgressView().padding() }
            if report.isEmpty {
                VStack(spacing:14) {
                    Image(systemName:"arrow.left.arrow.right.circle").font(.system(size:54,weight:.light)).foregroundStyle(ESTheme.gold)
                    Text("Positive evidence + negative evidence").font(.title2.bold())
                    Text("This is where the merged app becomes more than two trackers sharing rent. Apple Intelligence can surface recurring friction, invisible labor, preventive work, responsibility drift, and systems that repeatedly consume your attention without pretending correlation is proof of causation.").multilineTextAlignment(.center).foregroundStyle(ESTheme.muted).frame(maxWidth:700)
                }.frame(maxWidth:.infinity,maxHeight:.infinity)
            } else {
                TextEditor(text:$report).font(.system(size:14)).scrollContentBackground(.hidden).padding(18).background(ESTheme.canvas)
            }
        }.frame(minWidth:900,minHeight:680).background(ESTheme.canvas).foregroundStyle(.white)
    }
    @MainActor private func run() async { guard !running else{return}; running=true; error=nil; defer{running=false}; do{report=try await UnifiedWorkAIService.analyze(incidents:incidentStore.incidents,accomplishments:accomplishmentStore.accomplishments,year:year)}catch{self.error=error.localizedDescription} }
}
