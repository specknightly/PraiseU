import AppKit
import SwiftUI

struct EvidenceTabView: View {
    @EnvironmentObject private var store: IncidentStore
    let incidentID: UUID
    @State private var verificationNonce = UUID()

    private var items: [EvidenceItem] {
        store.incident(id: incidentID)?.evidence ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Evidence")
                        .font(.system(size: 18, weight: .bold))
                    Text("Files are copied into the incident store and hashed with SHA-256 when imported. The original source file is not modified.")
                        .font(.system(size: 12))
                        .foregroundStyle(ESTheme.muted)
                }
                Spacer()
                Button {
                    addEvidence()
                } label: {
                    Label("Attach Evidence", systemImage: "paperclip")
                }
                .buttonStyle(.borderedProminent)
                .tint(ESTheme.accent)

                Button {
                    verificationNonce = UUID()
                } label: {
                    Label("Verify All", systemImage: "checkmark.shield")
                }
                .buttonStyle(.bordered)
                .disabled(items.isEmpty)
            }

            if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 36))
                        .foregroundStyle(ESTheme.muted)
                    Text("No evidence attached")
                        .font(.headline)
                    Text("Screenshots, exported emails, PDFs, logs, ticket records, photos, and other source material can be attached here.")
                        .foregroundStyle(ESTheme.muted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 460)
                }
                .frame(maxWidth: .infinity, minHeight: 340)
                .panelBackground()
            } else {
                LazyVStack(spacing: 11) {
                    ForEach(items) { item in
                        EvidenceRow(item: item, incidentID: incidentID, verificationNonce: verificationNonce)
                    }
                }
            }
        }
    }

    private func addEvidence() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.resolvesAliases = true
        panel.message = "Choose screenshots, PDFs, logs, emails, or other incident evidence."
        if panel.runModal() == .OK {
            do {
                try store.importEvidence(urls: panel.urls, into: incidentID)
            } catch {
                store.lastError = "Could not attach evidence: \(error.localizedDescription)"
            }
        }
    }
}

private struct EvidenceRow: View {
    @EnvironmentObject private var store: IncidentStore
    let item: EvidenceItem
    let incidentID: UUID
    let verificationNonce: UUID
    @State private var note: String = ""
    @State private var showDelete = false

    private var fileURL: URL { store.evidenceURL(for: item, incidentID: incidentID) }
    private var verified: Bool { store.verifyEvidence(item, incidentID: incidentID) }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            EvidenceThumbnail(url: fileURL)
                .frame(width: 145, height: 100)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.originalName)
                    .font(.system(size: 13.5, weight: .semibold))
                    .lineLimit(2)
                HStack(spacing: 10) {
                    Label(item.importedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                    Label(ByteCountFormatter.string(fromByteCount: item.byteCount, countStyle: .file), systemImage: "doc")
                    Label(verified ? "Hash verified" : "Hash mismatch", systemImage: verified ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(verified ? Color.green.opacity(0.88) : ESTheme.danger)
                        .id(verificationNonce)
                }
                .font(.system(size: 10.5))
                .foregroundStyle(ESTheme.muted)

                Text("SHA-256  \(item.sha256)")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(ESTheme.muted)
                    .textSelection(.enabled)

                TextField("Evidence note or provenance...", text: $note)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 9)
                    .frame(height: 30)
                    .background(ESTheme.field)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .onSubmit {
                        store.updateEvidenceNote(item.id, incidentID: incidentID, note: note)
                    }
            }

            VStack(spacing: 7) {
                Button("Open") { NSWorkspace.shared.open(fileURL) }
                    .buttonStyle(.bordered)
                Button("Reveal") { NSWorkspace.shared.activateFileViewerSelecting([fileURL]) }
                    .buttonStyle(.bordered)
                Button(role: .destructive) {
                    showDelete = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(13)
        .panelBackground(radius: 10)
        .onAppear { note = item.note }
        .confirmationDialog("Remove this evidence file?", isPresented: $showDelete) {
            Button("Remove Evidence", role: .destructive) {
                store.removeEvidence(item.id, from: incidentID)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct EvidenceThumbnail: View {
    let url: URL

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(ESTheme.field)
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            } else {
                VStack(spacing: 7) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 42, height: 42)
                    Text(url.pathExtension.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(ESTheme.muted)
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ESTheme.border))
    }
}
