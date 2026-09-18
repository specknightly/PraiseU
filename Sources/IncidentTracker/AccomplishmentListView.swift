import SwiftUI

struct AccomplishmentListView: View {
    let accomplishments: [AccomplishmentRecord]
    let selection: AccomplishmentSidebarSelection
    @Binding var selectedID: UUID?
    @Binding var sort: AccomplishmentSort

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).font(.system(size: 20, weight: .bold)); Spacer()
                Picker("Sort", selection: $sort) { ForEach(AccomplishmentSort.allCases) { Text($0.rawValue).tag($0) } }
                    .labelsHidden().frame(width: 155)
            }.padding(.horizontal, 18).frame(height: 66)

            if accomplishments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy").font(.system(size: 34)).foregroundStyle(ESTheme.gold)
                    Text("No matching accomplishments").font(.headline)
                    Text("Useful work has an unfortunate habit of becoming invisible unless somebody records it.").font(.subheadline).foregroundStyle(ESTheme.muted).multilineTextAlignment(.center).frame(maxWidth: 300)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 5) {
                        ForEach(accomplishments) { item in
                            Button { selectedID = item.id } label: {
                                HStack(alignment: .top, spacing: 13) {
                                    Image(systemName: item.category.symbol).font(.system(size: 24, weight: .medium)).foregroundStyle(ESTheme.gold).frame(width: 34, height: 34)
                                    VStack(alignment: .leading, spacing: 7) {
                                        HStack(alignment: .top) {
                                            Text(item.title).font(.system(size: 14, weight: .semibold)).multilineTextAlignment(.leading).lineLimit(3)
                                            Spacer(minLength: 6)
                                            if item.isPinned { Image(systemName: "pin.fill").foregroundStyle(ESTheme.gold) }
                                        }
                                        HStack(spacing: 7) {
                                            Text(item.date.formatted(date: .abbreviated, time: .omitted)); Text("•"); Text(item.isDraft ? "Draft" : "Completed")
                                        }.font(.system(size: 11)).foregroundStyle(selectedID == item.id ? ESTheme.textPrimary.opacity(0.82) : ESTheme.muted)
                                        HStack(spacing: 6) {
                                            accomplishmentPill(item.category.rawValue, selected: selectedID == item.id)
                                            if let tag = item.tags.first { accomplishmentPill(tag, selected: selectedID == item.id) }
                                            if !item.evidence.isEmpty { Label("\(item.evidence.count)", systemImage: "paperclip").font(.system(size: 10, weight: .semibold)).foregroundStyle(selectedID == item.id ? ESTheme.goldSoft : ESTheme.muted) }
                                        }
                                    }
                                }
                                .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                                .background(selectedID == item.id ? ESTheme.selection : ESTheme.panel)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedID == item.id ? ESTheme.borderStrong : ESTheme.border))
                            }.buttonStyle(.plain)
                        }
                    }.padding(.horizontal, 10).padding(.bottom, 16)
                }
            }
        }.background(ESTheme.canvas)
    }

    private func accomplishmentPill(_ text: String, selected: Bool) -> some View {
        Text(text).font(.system(size: 10, weight: .medium)).lineLimit(1).padding(.horizontal, 7).padding(.vertical, 4)
            .background(selected ? ESTheme.gold.opacity(0.15) : ESTheme.panelRaised).clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var title: String {
        switch selection {
        case .all: return "All Accomplishments"
        case .thisYear: return "This Year"
        case .pinned: return "Pinned"
        case .drafts: return "Drafts"
        case .completed: return "Completed"
        case .reviewPrep: return "Review Prep"
        case .insights: return "Professional Insights"
        case .intake: return "Automation & Intake"
        case .category(let c): return c.rawValue
        case .tag(let t): return "#\(t)"
        }
    }
}
