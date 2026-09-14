import SwiftUI
import SwiftData
import AppKit

/// Deliberately just two fields. The full Evidence Framework is where an accomplishment gets
/// structured for a review packet, but that structuring is exactly the friction that stops people
/// from capturing anything in the moment. This exists so the capture and the polish can happen
/// at different times.
struct QuickCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow

    @State private var title = ""
    @State private var note = ""
    @State private var didSave = false

    /// `dismiss()` only does something when SwiftUI itself is managing presentation, which is true
    /// for the menu bar popover but not for the hotkey panel (a plain NSPanel we show ourselves) —
    /// that path supplies this to actually close the window.
    var onRequestClose: (() -> Void)?

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Capture").font(.headline)
            Text("Jot it down now, while it's fresh. Add evidence and details later.")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("What did you just do?", text: $title)
                .textFieldStyle(.roundedBorder)
                .onSubmit { if canSave { saveAndReset() } }

            TextEditor(text: $note)
                .font(.body)
                .frame(height: 70)
                .padding(6)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                .overlay { RoundedRectangle(cornerRadius: 8).stroke(.quaternary, lineWidth: 1) }

            if didSave {
                Label("Saved to today's evidence.", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            HStack {
                Button("Save & Open") {
                    if let entry = save() { openInEditor(entry) }
                }
                .disabled(!canSave)

                Button("Save") { saveAndReset() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)

                Spacer()

                Button("Close") { dismiss(); onRequestClose?() }
                    .buttonStyle(.borderless)
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private func saveAndReset() {
        guard save() != nil else { return }
        title = ""
        note = ""
        didSave = true
    }

    @discardableResult
    private func save() -> Accomplishment? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty || !trimmedNote.isEmpty else { return nil }
        let entry = Accomplishment(
            date: .now,
            title: trimmedTitle.isEmpty ? "Untitled accomplishment" : trimmedTitle,
            category: .other,
            context: trimmedNote
        )
        entry.evidenceNotes = "Captured from the menu bar quick-capture popover."
        modelContext.insert(entry)
        try? modelContext.save()
        return entry
    }

    private func openInEditor(_ entry: Accomplishment) {
        NotificationCenter.default.post(name: .revealAccomplishment, object: entry.id)
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.isVisible && $0.contentViewController != nil }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: "main")
        }
        dismiss()
        onRequestClose?()
    }
}
