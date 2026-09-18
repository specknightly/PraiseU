import SwiftUI

struct AccomplishmentIntakeView: View {
    @EnvironmentObject private var store: AccomplishmentStore
    @AppStorage("autoScanEvidenceInbox") private var autoScan=true
    @State private var status=""
    @State private var mailboxes:[MailboxDescriptor]=[]
    @State private var evidenceMailboxID=""
    @State private var requestMailboxID=""
    @AppStorage("evidenceMailAccount") private var evidenceMailAccount=""
    @AppStorage("evidenceMailPath") private var evidenceMailPath=""
    @AppStorage("requestMailAccount") private var requestMailAccount=""
    @AppStorage("requestMailPath") private var requestMailPath=""
    @State private var requestOutput=""
    @State private var loadingMail=false
    var body: some View {
        ScrollView { VStack(alignment:.leading,spacing:20) {
            Text("Automation & Intake").font(.system(size:30,weight:.bold)); Text("Capture work while it is fresh, then enrich it later. Everything here stays local unless you explicitly hand data to another app.").foregroundStyle(ESTheme.muted)
            panel("Evidence Inbox","Drop screenshots, PDFs, logs, Markdown, text, or JSON into a watched local folder. Files become accomplishment drafts and are moved into Processed after import.") {
                Toggle("Scan Evidence Inbox when the app becomes active",isOn:$autoScan)
                HStack { Button("Reveal Inbox in Finder"){AccomplishmentIntakeService.revealInbox()}; Button("Scan Now"){ do { let n=try AccomplishmentIntakeService.scanInbox(store:store); status="Imported \(n) item(s)." } catch { status=error.localizedDescription } } }
            }
            panel("URL / Shortcuts Capture","Use entropyshield://capture?title=...&note=... or accomplishmenttracker://capture?... from Shortcuts and local scripts. External captures are tagged needs-review by design.") { Text("Useful for tiny automations that should not need database access.").foregroundStyle(ESTheme.muted) }
            panel("Menu Bar Quick Capture","The menu-bar pencil captures a title and note without opening the main window. Flesh it out later when the dopamine from fixing the thing has worn off.") { Text("Quick captures are stored as drafts with needs-review tagging.").foregroundStyle(ESTheme.muted) }
            panel("Apple Mail Evidence","Optionally read one explicitly selected Apple Mail mailbox and turn new messages into accomplishment drafts. macOS will request Automation permission.") {
                HStack { Button(loadingMail ? "Loading…" : "Load Mailboxes") { Task { await loadMailboxes() } }.disabled(loadingMail); Picker("Evidence mailbox",selection:$evidenceMailboxID){ Text("Select…").tag(""); ForEach(mailboxes){Text($0.displayName).tag($0.id)} }.frame(maxWidth:430) }
                Button("Import New Mail Evidence") { Task { await importMailEvidence() } }.disabled(evidenceMailboxID.isEmpty)
            }
            panel("Request Intelligence (Experimental)","Use a separate Mail mailbox for incoming work requests. Apple Intelligence summarizes the request, recalls relevant accomplishment context, identifies ambiguity, and drafts a response locally for your review.") {
                HStack { Picker("Request mailbox",selection:$requestMailboxID){ Text("Select…").tag(""); ForEach(mailboxes){Text($0.displayName).tag($0.id)} }.frame(maxWidth:430); Button("Analyze Latest Request") { Task { await analyzeLatestRequest() } }.disabled(requestMailboxID.isEmpty || loadingMail) }
                if !requestOutput.isEmpty { TextEditor(text:$requestOutput).frame(minHeight:240).scrollContentBackground(.hidden).padding(8).background(ESTheme.field).clipShape(RoundedRectangle(cornerRadius:9)) }
            }

            panel("Role Baseline & Scope Expectations","These settings drive scope-drift analysis, raise-case stress testing, and the longitudinal Professional Value Model.") {
                TextEditor(text: Binding(get:{ UserDefaults.standard.string(forKey:"coreRoleDefinition") ?? "" }, set:{ UserDefaults.standard.set($0,forKey:"coreRoleDefinition") })).frame(minHeight:90).scrollContentBackground(.hidden).padding(8).background(ESTheme.field).clipShape(RoundedRectangle(cornerRadius:9))
                HStack { Text("Expected adjacent / out-of-role work"); Slider(value: Binding(get:{ UserDefaults.standard.double(forKey:"expectedOtherPercent") == 0 ? 10 : UserDefaults.standard.double(forKey:"expectedOtherPercent") }, set:{ UserDefaults.standard.set($0,forKey:"expectedOtherPercent") }),in:0...100,step:5); Text("\(Int(UserDefaults.standard.double(forKey:"expectedOtherPercent") == 0 ? 10 : UserDefaults.standard.double(forKey:"expectedOtherPercent")))%").frame(width:45) }
            }
            if !status.isEmpty { Text(status).foregroundStyle(ESTheme.gold) }
        }.padding(28) }.background(ESTheme.canvas)
        .onChange(of:evidenceMailboxID) { _, id in if let b=mailboxes.first(where:{$0.id==id}) { evidenceMailAccount=b.account; evidenceMailPath=b.path } }
        .onChange(of:requestMailboxID) { _, id in if let b=mailboxes.first(where:{$0.id==id}) { requestMailAccount=b.account; requestMailPath=b.path } }
    }
    @MainActor private func loadMailboxes() async {
        loadingMail=true; defer { loadingMail=false }
        do {
            mailboxes = try AppleMailWorkIntelligenceService.availableMailboxes()
            if let b=mailboxes.first(where:{$0.account==evidenceMailAccount && $0.path==evidenceMailPath}) { evidenceMailboxID=b.id }
            if let b=mailboxes.first(where:{$0.account==requestMailAccount && $0.path==requestMailPath}) { requestMailboxID=b.id }
            status = "Found \(mailboxes.count) mailbox(es)."
        }
        catch { status = error.localizedDescription }
    }
    @MainActor private func importMailEvidence() async {
        guard let box=mailboxes.first(where:{$0.id==evidenceMailboxID}) else{return}
        do { let n=try AppleMailWorkIntelligenceService.importEvidence(account:box.account,path:box.path,store:store); status="Imported \(n) new Mail evidence item(s)." }
        catch { status=error.localizedDescription }
    }
    @MainActor private func analyzeLatestRequest() async {
        guard let box=mailboxes.first(where:{$0.id==requestMailboxID}) else{return}; loadingMail=true; defer{loadingMail=false}
        do { guard let m=try AppleMailWorkIntelligenceService.fetch(account:box.account,path:box.path,limit:1).first else { status="No request messages found."; return }; requestOutput=try await AppleMailWorkIntelligenceService.requestIntelligence(message:m,accomplishments:store.accomplishments); status="Analyzed latest request locally." }
        catch { status=error.localizedDescription }
    }

    private func panel<Content:View>(_ title:String,_ detail:String,@ViewBuilder content:()->Content)->some View { VStack(alignment:.leading,spacing:12){Text(title).font(.title3.bold());Text(detail).foregroundStyle(ESTheme.muted);content()}.padding(18).frame(maxWidth:.infinity,alignment:.leading).background(ESTheme.panel).clipShape(RoundedRectangle(cornerRadius:12)).overlay(RoundedRectangle(cornerRadius:12).stroke(ESTheme.border)) }
}
