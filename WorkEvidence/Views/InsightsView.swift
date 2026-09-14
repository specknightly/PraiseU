import SwiftUI
import Charts

struct InsightsView: View {
    let entries: [Accomplishment]
    @AppStorage("expectedOtherPercent") private var expectedOtherPercent = 10.0
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)

    private var availableYears: [Int] {
        let years = Set(entries.map { Calendar.current.component(.year, from: $0.date) })
        let current = Calendar.current.component(.year, from: .now)
        return Array(years.union([current])).sorted(by: >)
    }

    private var yearEntries: [Accomplishment] {
        entries.filter { Calendar.current.component(.year, from: $0.date) == selectedYear }
    }

    private var classifiedScopeEntries: [Accomplishment] {
        yearEntries.filter { $0.responsibilityScope != .unclassified }
    }

    private var scopeDriftPercent: Double {
        guard !classifiedScopeEntries.isEmpty else { return 0 }
        let other = classifiedScopeEntries.filter { $0.responsibilityScope == .other }.count
        return (Double(other) / Double(classifiedScopeEntries.count)) * 100
    }

    private var evidenceCoverage: Double {
        guard !yearEntries.isEmpty else { return 0 }
        let withEvidence = yearEntries.filter { !$0.attachments.isEmpty || !($0.evidenceAnalysis ?? "").isEmpty || !$0.evidenceNotes.isEmpty }.count
        return Double(withEvidence) / Double(yearEntries.count) * 100
    }

    private var averageClaimStrength: Double {
        let scores = yearEntries.compactMap(\.claimStrength)
        guard !scores.isEmpty else { return 0 }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }

    private var advancedWorkPercent: Double {
        let classified = yearEntries.filter { $0.workLevel != .unclassified }
        guard !classified.isEmpty else { return 0 }
        let advanced = classified.filter { [.advanced, .specialist, .projectOwner, .strategic].contains($0.workLevel) }.count
        return Double(advanced) / Double(classified.count) * 100
    }

    private var evidenceHealthScore: Int {
        guard !yearEntries.isEmpty else { return 0 }
        // Documentation quality, not an employee-performance grade.
        let claimComponent = min(100, averageClaimStrength) * 0.45
        let evidenceComponent = evidenceCoverage * 0.35
        let enrichmentCoverage = Double(yearEntries.filter { $0.professionalIntelligenceGeneratedAt != nil }.count) / Double(yearEntries.count) * 100
        let enrichmentComponent = enrichmentCoverage * 0.20
        return Int((claimComponent + evidenceComponent + enrichmentComponent).rounded())
    }

    private var categoryData: [CountDatum] {
        AccomplishmentCategory.allCases.compactMap { category in
            let count = yearEntries.filter { $0.category == category }.count
            return count > 0 ? CountDatum(name: category.rawValue, count: count) : nil
        }.sorted { $0.count > $1.count }
    }

    private var scopeData: [CountDatum] {
        ResponsibilityScope.allCases.compactMap { scope in
            let count = yearEntries.filter { $0.responsibilityScope == scope }.count
            return count > 0 ? CountDatum(name: scope.rawValue, count: count) : nil
        }
    }

    private var workLevelData: [CountDatum] {
        WorkLevel.allCases.compactMap { level in
            let count = yearEntries.filter { $0.workLevel == level }.count
            return count > 0 ? CountDatum(name: level.rawValue, count: count) : nil
        }
    }

    private var monthData: [MonthDatum] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return (1...12).map { month in
            var components = DateComponents()
            components.year = selectedYear
            components.month = month
            components.day = 1
            let date = calendar.date(from: components) ?? .now
            let count = yearEntries.filter { calendar.component(.month, from: $0.date) == month }.count
            return MonthDatum(month: formatter.string(from: date), monthNumber: month, count: count)
        }
    }

    private var claimBandData: [CountDatum] {
        let bands: [(String, ClosedRange<Int>)] = [
            ("0–39", 0...39),
            ("40–59", 40...59),
            ("60–79", 60...79),
            ("80–100", 80...100)
        ]
        return bands.map { label, range in
            CountDatum(name: label, count: yearEntries.compactMap(\.claimStrength).filter { range.contains($0) }.count)
        }
    }

    private var topTagData: [CountDatum] {
        var counts: [String: Int] = [:]
        for entry in yearEntries {
            for tag in entry.tags {
                counts[tag, default: 0] += 1
            }
        }
        return counts.map { CountDatum(name: $0.key, count: $0.value) }
            .sorted { lhs, rhs in lhs.count == rhs.count ? lhs.name < rhs.name : lhs.count > rhs.count }
            .prefix(10)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                metricGrid

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    chartCard("Where Your Work Goes", subtitle: "Accomplishments by category") {
                        if categoryData.isEmpty { emptyChart } else {
                            Chart(categoryData) { item in
                                SectorMark(angle: .value("Accomplishments", item.count), innerRadius: .ratio(0.58), angularInset: 2)
                                    .foregroundStyle(by: .value("Category", item.name))
                            }
                            .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
                        }
                    }

                    chartCard("Responsibility Scope", subtitle: "Observed scope drift versus your role baseline") {
                        if scopeData.isEmpty { emptyChart } else {
                            Chart(scopeData) { item in
                                SectorMark(angle: .value("Accomplishments", item.count), innerRadius: .ratio(0.62), angularInset: 3)
                                    .foregroundStyle(by: .value("Scope", item.name))
                            }
                            .chartLegend(position: .bottom, alignment: .leading)
                            .overlay {
                                VStack(spacing: 2) {
                                    Text("\(Int(scopeDriftPercent.rounded()))%")
                                        .font(.title.bold()).monospacedDigit()
                                    Text("scope drift")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    chartCard("Work Level", subtitle: "Complexity and ownership represented in your record") {
                        Chart(workLevelData) { item in
                            BarMark(x: .value("Count", item.count), y: .value("Level", item.name))
                                .annotation(position: .trailing) { Text("\(item.count)").font(.caption).foregroundStyle(.secondary) }
                        }
                        .chartLegend(.hidden)
                    }

                    chartCard("Monthly Momentum", subtitle: "Documented accomplishments across \(selectedYear)") {
                        Chart(monthData) { item in
                            AreaMark(x: .value("Month", item.monthNumber), y: .value("Accomplishments", item.count))
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(.linearGradient(colors: [.accentColor.opacity(0.34), .accentColor.opacity(0.03)], startPoint: .top, endPoint: .bottom))
                            LineMark(x: .value("Month", item.monthNumber), y: .value("Accomplishments", item.count))
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))
                            PointMark(x: .value("Month", item.monthNumber), y: .value("Accomplishments", item.count))
                        }
                        .chartXAxis {
                            AxisMarks(values: monthData.map(\.monthNumber)) { value in
                                AxisGridLine()
                                AxisTick()
                                if let month = value.as(Int.self), let datum = monthData.first(where: { $0.monthNumber == month }) {
                                    AxisValueLabel(datum.month)
                                }
                            }
                        }
                    }

                    chartCard("Claim Strength", subtitle: "How defensible the documented claims are") {
                        Chart(claimBandData) { item in
                            BarMark(x: .value("Band", item.name), y: .value("Accomplishments", item.count))
                                .cornerRadius(5)
                        }
                        .chartLegend(.hidden)
                    }

                    chartCard("Top Demonstrated Themes", subtitle: "Most frequent tags in your evidence record") {
                        if topTagData.isEmpty { emptyChart } else {
                            Chart(topTagData) { item in
                                BarMark(x: .value("Count", item.count), y: .value("Tag", item.name))
                                    .annotation(position: .trailing) { Text("\(item.count)").font(.caption).foregroundStyle(.secondary) }
                            }
                            .chartLegend(.hidden)
                        }
                    }
                }

                scopeComparisonCard
                methodologyCard
            }
            .padding(24)
        }
        .navigationTitle("Professional Insights")
        .onChange(of: availableYears) { _, years in
            if !years.contains(selectedYear), let first = years.first { selectedYear = first }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Professional Insights")
                    .font(.largeTitle.bold())
                Text("Visualize what your documented work demonstrates, not just how many entries you have.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Picker("Year", selection: $selectedYear) {
                ForEach(availableYears, id: \.self) { year in Text(String(year)).tag(year) }
            }
            .frame(width: 150)
        }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
            metricCard("Accomplishments", value: "\(yearEntries.count)", detail: "documented this year", symbol: "checkmark.seal")
            metricCard("Evidence Health", value: "\(evidenceHealthScore)", detail: "out of 100", symbol: "shield.checkered")
            metricCard("Scope Drift", value: "\(Int(scopeDriftPercent.rounded()))%", detail: "expected \(Int(expectedOtherPercent))%", symbol: "arrow.up.right.circle")
            metricCard("Advanced+ Work", value: "\(Int(advancedWorkPercent.rounded()))%", detail: "of classified work", symbol: "brain.head.profile")
            metricCard("Evidence Coverage", value: "\(Int(evidenceCoverage.rounded()))%", detail: "with supporting proof", symbol: "paperclip")
            metricCard("Avg Claim Strength", value: averageClaimStrength == 0 ? "—" : "\(Int(averageClaimStrength.rounded()))", detail: "AI defensibility score", symbol: "checkmark.shield")
            metricCard("Attachments", value: "\(yearEntries.reduce(0) { $0 + $1.attachments.count })", detail: "supporting files", symbol: "doc.on.doc")
            metricCard("AI Enriched", value: "\(yearEntries.filter { $0.professionalIntelligenceGeneratedAt != nil }.count)", detail: "professional analyses", symbol: "sparkles")
        }
    }

    private var scopeComparisonCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Scope Drift vs. Expected Baseline").font(.headline)
            Text("This comparison is especially useful when your official role says one thing and the accumulated evidence says something substantially more adventurous.")
                .font(.callout).foregroundStyle(.secondary)

            Chart {
                BarMark(x: .value("Percent", expectedOtherPercent), y: .value("Series", "Expected Other Work"))
                    .foregroundStyle(.secondary)
                    .annotation(position: .trailing) { Text("\(Int(expectedOtherPercent))%").font(.caption) }
                BarMark(x: .value("Percent", scopeDriftPercent), y: .value("Series", "Observed Scope Drift"))
                    .foregroundStyle(Color.accentColor)
                    .annotation(position: .trailing) { Text("\(Int(scopeDriftPercent.rounded()))%").font(.caption.bold()) }
            }
            .chartXScale(domain: 0...100)
            .frame(height: 120)
        }
        .insightCardStyle()
    }

    private var methodologyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("How to read these numbers", systemImage: "info.circle")
                .font(.headline)
            Text("Evidence Health measures documentation quality, not your worth as an employee. It combines average AI claim-strength (45%), evidence coverage (35%), and Professional Intelligence coverage (20%). Scope Drift is calculated only from accomplishments already classified as Core Role or Other / Scope Drift. Advanced+ Work includes Advanced, Specialist, Project Owner, and Strategic / Leadership classifications.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .insightCardStyle()
    }

    @ViewBuilder
    private func chartCard<Content: View>(_ title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            content()
                .frame(minHeight: 240, idealHeight: 270)
        }
        .insightCardStyle()
    }

    private func metricCard(_ title: String, value: String, detail: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 105, alignment: .leading)
        .insightCardStyle()
    }

    private var emptyChart: some View {
        ContentUnavailableView("Not enough data", systemImage: "chart.bar", description: Text("Add or classify more accomplishments to populate this view."))
    }
}

private struct CountDatum: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

private struct MonthDatum: Identifiable {
    let id = UUID()
    let month: String
    let monthNumber: Int
    let count: Int
}

private extension View {
    func insightCardStyle() -> some View {
        self
            .padding(16)
            .background(.quaternary.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.quaternary, lineWidth: 1) }
    }
}
