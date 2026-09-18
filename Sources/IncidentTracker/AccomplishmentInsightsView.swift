import SwiftUI
import Charts

struct AccomplishmentInsightsView: View {
    @EnvironmentObject private var store: AccomplishmentStore
    @AppStorage("expectedOtherPercent") private var expectedOtherPercent = 10.0
    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    private var entries: [AccomplishmentRecord] {
        store.accomplishments.filter { Calendar.current.component(.year, from: $0.date) == selectedYear }
    }
    private var evidenceCoverage: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.filter { !$0.evidence.isEmpty || !$0.evidenceNotes.isEmpty }.count) / Double(entries.count) * 100
    }
    private var scopeDrift: Double {
        let classified = entries.filter { $0.responsibilityScope != .unclassified }
        guard !classified.isEmpty else { return 0 }
        return Double(classified.filter { $0.responsibilityScope == .other }.count) / Double(classified.count) * 100
    }
    private var averageClaim: Double {
        let values = entries.map(\.claimStrength).filter { $0 > 0 }
        guard !values.isEmpty else { return 0 }
        return Double(values.reduce(0,+))/Double(values.count)
    }
    private var advancedPercent: Double {
        let classified = entries.filter { $0.workLevel != .unclassified }
        guard !classified.isEmpty else { return 0 }
        let advanced: Set<WorkLevel> = [.advanced,.specialist,.projectOwner,.strategic]
        return Double(classified.filter { advanced.contains($0.workLevel) }.count)/Double(classified.count)*100
    }
    private var categories: [(String,Int)] {
        AccomplishmentCategory.allCases.compactMap { c in
            let n = entries.filter { $0.category == c }.count
            return n > 0 ? (c.rawValue,n) : nil
        }.sorted { $0.1 > $1.1 }
    }
    private var months: [(String,Int)] {
        let f = DateFormatter(); f.dateFormat = "MMM"
        return (1...12).map { month in
            let n = entries.filter { Calendar.current.component(.month, from:$0.date) == month }.count
            let d = Calendar.current.date(from: DateComponents(year:selectedYear,month:month,day:1))!
            return (f.string(from:d),n)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:22) {
                HStack {
                    VStack(alignment:.leading,spacing:4) {
                        Text("Professional Insights").font(.system(size:30,weight:.bold))
                        Text("Documentation quality, scope drift, work level and evidence trends. These measure the record, not your worth as a human. Apparently that distinction needs software now.").foregroundStyle(ESTheme.muted)
                    }
                    Spacer()
                    Picker("Year",selection:$selectedYear) {
                        ForEach(Array(Set(store.accomplishments.map { Calendar.current.component(.year, from: $0.date) }).union([Calendar.current.component(.year, from: Date())])).sorted(by: >), id: \.self) { year in Text(String(year)).tag(year) }
                    }.frame(width:120)
                }
                LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:12),count:4),spacing:12) {
                    metric("Records", "\(entries.count)", "doc.text")
                    metric("Evidence Coverage", String(format:"%.0f%%",evidenceCoverage), "paperclip")
                    metric("Claim Strength", String(format:"%.0f/100",averageClaim), "checkmark.shield")
                    metric("Advanced Work", String(format:"%.0f%%",advancedPercent), "brain.head.profile")
                }
                HStack(spacing:16) {
                    chartCard("Category Mix") {
                        Chart(categories,id:\.0) { item in BarMark(x:.value("Count",item.1),y:.value("Category",item.0)) }
                            .chartXAxis(.hidden).frame(height:260)
                    }
                    chartCard("Monthly Momentum") {
                        Chart(months,id:\.0) { item in LineMark(x:.value("Month",item.0),y:.value("Records",item.1)); PointMark(x:.value("Month",item.0),y:.value("Records",item.1)) }
                            .frame(height:260)
                    }
                }
                HStack(spacing:16) {
                    insightCard("Scope Drift", value:String(format:"%.0f%%",scopeDrift), detail:"Expected adjacent work: \(Int(expectedOtherPercent))%. A persistent gap can support a role-scope conversation when the underlying records are defensible.")
                    insightCard("Evidence Health", value:String(format:"%.0f%%",evidenceCoverage), detail:"Records backed by attached evidence or explicit evidence notes. Thin documentation is a fixable problem, unlike the annual-review ritual itself.")
                }
            }.padding(28)
        }.background(ESTheme.canvas)
    }

    private func metric(_ title:String,_ value:String,_ symbol:String)->some View {
        VStack(alignment:.leading,spacing:8){ Label(title,systemImage:symbol).foregroundStyle(ESTheme.muted); Text(value).font(.system(size:28,weight:.bold)).foregroundStyle(ESTheme.gold) }
            .frame(maxWidth:.infinity,alignment:.leading).padding(16).background(ESTheme.panel).clipShape(RoundedRectangle(cornerRadius:12)).overlay(RoundedRectangle(cornerRadius:12).stroke(ESTheme.border))
    }
    private func chartCard<Content:View>(_ title:String,@ViewBuilder content:()->Content)->some View {
        VStack(alignment:.leading,spacing:12){ Text(title).font(.title3.bold()); content() }.padding(18).frame(maxWidth:.infinity).background(ESTheme.panel).clipShape(RoundedRectangle(cornerRadius:12)).overlay(RoundedRectangle(cornerRadius:12).stroke(ESTheme.border))
    }
    private func insightCard(_ title:String,value:String,detail:String)->some View {
        VStack(alignment:.leading,spacing:10){ Text(title).font(.title3.bold()); Text(value).font(.system(size:38,weight:.bold)).foregroundStyle(ESTheme.gold); Text(detail).foregroundStyle(ESTheme.muted) }.padding(18).frame(maxWidth:.infinity,minHeight:150,alignment:.topLeading).background(ESTheme.panel).clipShape(RoundedRectangle(cornerRadius:12)).overlay(RoundedRectangle(cornerRadius:12).stroke(ESTheme.border))
    }
}
