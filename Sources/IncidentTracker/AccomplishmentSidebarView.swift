import SwiftUI

struct AccomplishmentSidebarView: View {
    @EnvironmentObject private var store: AccomplishmentStore
    @Binding var selection: AccomplishmentSidebarSelection
    @State private var categoriesExpanded = true
    @State private var tagsExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    AccomplishmentSidebarButton("All Accomplishments", symbol: "tray.full", count: store.totalCount, selected: selection == .all) { selection = .all }
                    AccomplishmentSidebarButton("This Year", symbol: "calendar", count: store.thisYearCount, selected: selection == .thisYear) { selection = .thisYear }
                    AccomplishmentSidebarButton("Pinned", symbol: "pin", count: store.pinnedCount, selected: selection == .pinned) { selection = .pinned }
                    AccomplishmentSidebarButton("Drafts", symbol: "pencil", count: store.draftCount, selected: selection == .drafts) { selection = .drafts }
                    AccomplishmentSidebarButton("Completed", symbol: "checkmark.circle", count: store.completedCount, selected: selection == .completed) { selection = .completed }
                    AccomplishmentSidebarButton("Professional Insights", symbol: "chart.xyaxis.line", selected: selection == .insights) { selection = .insights }
                    AccomplishmentSidebarButton("Review Prep", symbol: "person.crop.circle.badge.questionmark", selected: selection == .reviewPrep) { selection = .reviewPrep }
                    AccomplishmentSidebarButton("Automation & Intake", symbol: "tray.and.arrow.down", selected: selection == .intake) { selection = .intake }

                    Divider().overlay(ESTheme.border).padding(.vertical, 10)

                    DisclosureGroup(isExpanded: $categoriesExpanded) {
                        VStack(spacing: 2) {
                            ForEach(AccomplishmentCategory.allCases) { category in
                                let count = store.accomplishments.filter { $0.category == category }.count
                                if count > 0 {
                                    AccomplishmentSidebarSubButton(category.rawValue, count: count, selected: selection == .category(category)) { selection = .category(category) }
                                }
                            }
                        }.padding(.top, 5)
                    } label: {
                        Label("Categories", systemImage: "folder").foregroundStyle(ESTheme.textPrimary)
                    }
                    .padding(.horizontal, 13).padding(.vertical, 7)

                    DisclosureGroup(isExpanded: $tagsExpanded) {
                        VStack(spacing: 2) {
                            ForEach(store.tags, id: \.self) { tag in
                                AccomplishmentSidebarSubButton(tag, count: store.accomplishments.filter { $0.tags.contains(tag) }.count, selected: selection == .tag(tag)) { selection = .tag(tag) }
                            }
                        }.padding(.top, 5)
                    } label: {
                        Label("Tags", systemImage: "tag").foregroundStyle(ESTheme.textPrimary)
                    }
                    .padding(.horizontal, 13).padding(.vertical, 7)
                }
                .padding(12)
            }
        }
        .background(ESTheme.sidebar)
    }
}

private struct AccomplishmentSidebarButton: View {
    let title: String; let symbol: String; var count: Int?; let selected: Bool; let action: () -> Void
    init(_ title: String, symbol: String, count: Int? = nil, selected: Bool, action: @escaping () -> Void) {
        self.title = title; self.symbol = symbol; self.count = count; self.selected = selected; self.action = action
    }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: symbol).font(.system(size: 16, weight: .medium)).frame(width: 22)
                Text(title).lineLimit(1); Spacer(minLength: 4)
                if let count { Text("\(count)").font(.system(size: 11, weight: .bold)).padding(.horizontal, 7).padding(.vertical, 3).background(selected ? ESTheme.gold.opacity(0.18) : ESTheme.textPrimary.opacity(0.07)).clipShape(Capsule()) }
            }
            .font(.system(size: 13, weight: selected ? .semibold : .medium))
            .foregroundStyle(selected ? ESTheme.gold : ESTheme.textPrimary.opacity(0.88))
            .padding(.horizontal, 12).frame(height: 43)
            .background(selected ? ESTheme.selection : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(selected ? ESTheme.borderStrong : Color.clear))
        }.buttonStyle(.plain)
    }
}

private struct AccomplishmentSidebarSubButton: View {
    let title: String; let count: Int; let selected: Bool; let action: () -> Void
    init(_ title: String, count: Int, selected: Bool, action: @escaping () -> Void) { self.title = title; self.count = count; self.selected = selected; self.action = action }
    var body: some View {
        Button(action: action) {
            HStack { Text(title).lineLimit(1); Spacer(); Text("\(count)").foregroundStyle(ESTheme.muted) }
                .font(.system(size: 12, weight: selected ? .semibold : .regular)).padding(.leading, 30).padding(.trailing, 8).frame(height: 29)
                .foregroundStyle(selected ? ESTheme.gold : ESTheme.textPrimary.opacity(0.72))
        }.buttonStyle(.plain)
    }
}
