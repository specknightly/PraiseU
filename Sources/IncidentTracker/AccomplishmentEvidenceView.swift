import AppKit
import SwiftUI

struct AccomplishmentEvidenceView: View {
    @EnvironmentObject private var store: AccomplishmentStore
    let accomplishmentID: UUID
    @State private var verificationNonce = UUID()

    private var items: [AccomplishmentEvidenceItem] { store.accomplishment(id: accomplishmentID)?.evidence ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Evidence").font(.system(size: 18, weight: .bold))
                    Text("Files are copied into the local accomplishment store and hashed with SHA-256 when imported.")
                        .font(.system(size: 12)).foregroundStyle(ESTheme.muted)
                }
                Spacer()
                Button { addEvidence() } label: { Label("Attach Evidence", systemImage: "paperclip") }
                    .buttonStyle(.borderedProminent).tint(ESTheme.accent)
            }

            if items.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "paperclip").font(.system(size: 30)).foregroundStyle(ESTheme.muted)
                    Text("No evidence attached").font(.headline)
                    Text("Attach screenshots, PDFs, exports, emails, or other durable proof that supports the accomplishment.")
                        .font(.subheadline).foregroundStyle(ESTheme.muted).multilineTextAlignment(.center).frame(maxWidth: 440)
                }.frame(maxWidth: .infinity, minHeight: 260)
            } else {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        HStack(spacing: 12) {
                            Image(systemName: "doc.fill").font(.system(size: 22)).foregroundStyle(ESTheme.gold).frame(width: 32)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.originalName).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                                Text(ByteCountFormatter.string(fromByteCount: item.byteCount, countStyle: .file) + "  •  SHA-256 " + String(item.sha256.prefix(12)) + "…")
                                    .font(.system(size: 10)).foregroundStyle(ESTheme.muted)
                                TextField("Evidence note", text: Binding(
                                    get: { store.accomplishment(id: accomplishmentID)?.evidence.first(where: { $0.id == item.id })?.note ?? "" },
                                    set: { store.updateEvidenceNote(item.id, accomplishmentID: accomplishmentID, note: $0) }
                                )).textFieldStyle(.plain).font(.system(size: 11))
                            }
                            Spacer()
                            Image(systemName: store.verifyEvidence(item, accomplishmentID: accomplishmentID) ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                                .foregroundStyle(store.verifyEvidence(item, accomplishmentID: accomplishmentID) ? ESTheme.accent : ESTheme.danger)
                                .id(verificationNonce)
                            Button { NSWorkspace.shared.open(store.evidenceURL(for: item, accomplishmentID: accomplishmentID)) } label: { Image(systemName: "arrow.up.forward.square") }.buttonStyle(.borderless)
                            Button(role: .destructive) { store.removeEvidence(item.id, from: accomplishmentID) } label: { Image(systemName: "trash") }.buttonStyle(.borderless)
                        }
                        .padding(12).background(ESTheme.field).clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                }
            }
        }.padding(16).panelBackground()
    }

    private func addEvidence() {
        let panel = NSOpenPanel(); panel.canChooseFiles = true; panel.canChooseDirectories = false; panel.allowsMultipleSelection = true
        if panel.runModal() == .OK {
            do { try store.importEvidence(urls: panel.urls, into: accomplishmentID); verificationNonce = UUID() }
            catch { store.lastError = "Could not attach evidence: \(error.localizedDescription)" }
        }
    }
}
