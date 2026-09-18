import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: IncidentStore
    @Binding var selection: SidebarSelection
    @State private var categoriesExpanded = false
    @State private var tagsExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    SidebarButton("All Incidents", symbol: "tray.full", count: store.totalCount, selected: selection == .all) {
                        selection = .all
                    }
                    SidebarButton("This Year", symbol: "calendar", count: store.thisYearCount, selected: selection == .thisYear) {
                        selection = .thisYear
                    }
                    SidebarButton("Pinned", symbol: "pin", count: store.pinnedCount, selected: selection == .pinned) {
                        selection = .pinned
                    }
                    SidebarButton("Drafts", symbol: "pencil", count: store.incidents.filter { $0.status == .draft }.count, selected: selection == .drafts) {
                        selection = .drafts
                    }
                    SidebarButton("Open / Monitoring", symbol: "exclamationmark.circle", count: store.openCount, selected: selection == .open) {
                        selection = .open
                    }
                    SidebarButton("Resolved / Closed", symbol: "checkmark.circle", count: store.resolvedCount, selected: selection == .resolved) {
                        selection = .resolved
                    }

                    Divider().overlay(ESTheme.border).padding(.vertical, 10)

                    DisclosureGroup(isExpanded: $categoriesExpanded) {
                        VStack(spacing: 2) {
                            ForEach(store.categories, id: \.self) { category in
                                SidebarSubButton(category, count: store.incidents.filter { $0.category == category }.count,
                                                 selected: selection == .category(category)) {
                                    selection = .category(category)
                                }
                            }
                        }
                        .padding(.top, 5)
                    } label: {
                        Label("Categories", systemImage: "folder")
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)

                    DisclosureGroup(isExpanded: $tagsExpanded) {
                        VStack(spacing: 2) {
                            ForEach(store.tags, id: \.self) { tag in
                                SidebarSubButton(tag, count: store.incidents.filter { $0.tags.contains(tag) }.count,
                                                 selected: selection == .tag(tag)) {
                                    selection = .tag(tag)
                                }
                            }
                        }
                        .padding(.top, 5)
                    } label: {
                        Label("Tags", systemImage: "tag")
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 7)

                    SidebarButton("Timeline", symbol: "clock.arrow.circlepath", selected: selection == .timeline) {
                        selection = .timeline
                    }
                    SidebarButton("Reports & Patterns", symbol: "chart.bar.xaxis", selected: selection == .reports) {
                        selection = .reports
                    }
                }
                .padding(12)
            }
        }
        .background(ESTheme.sidebar)
    }
}

private struct SidebarButton: View {
    let title: String
    let symbol: String
    var count: Int?
    let selected: Bool
    let action: () -> Void

    init(_ title: String, symbol: String, count: Int? = nil, selected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.count = count
        self.selected = selected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 22)
                Text(title)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if let count {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.white.opacity(selected ? 0.18 : 0.10))
                        .clipShape(Capsule())
                }
            }
            .font(.system(size: 13, weight: selected ? .semibold : .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 43)
            .background(selected ? ESTheme.accent.opacity(0.72) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct SidebarSubButton: View {
    let title: String
    let count: Int
    let selected: Bool
    let action: () -> Void

    init(_ title: String, count: Int, selected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.count = count
        self.selected = selected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).lineLimit(1)
                Spacer()
                Text("\(count)").foregroundStyle(ESTheme.muted)
            }
            .font(.system(size: 12, weight: selected ? .semibold : .regular))
            .padding(.leading, 30)
            .padding(.trailing, 8)
            .frame(height: 29)
            .foregroundStyle(selected ? ESTheme.gold : .white.opacity(0.78))
        }
        .buttonStyle(.plain)
    }
}
