import SwiftUI

struct QuickCaptureView: View {
    @EnvironmentObject private var store: AccomplishmentStore
    @State private var title = ""
    @State private var note = ""
    @State private var saved = false

    var body: some View {
        VStack(alignment:.leading,spacing:12) {
            Text("Quick Capture").font(.headline)
            TextField("What did you accomplish?",text:$title)
            TextField("Optional note",text:$note,axis:.vertical).lineLimit(2...5)
            HStack {
                if saved { Label("Saved",systemImage:"checkmark.circle.fill").foregroundStyle(.green) }
                Spacer()
                Button("Save") { save() }.keyboardShortcut(.return,modifiers:.command).disabled(title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && note.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
            }
        }.padding(16).frame(width:360)
    }
    private func save() {
        var r = store.createAccomplishment()
        r.title = title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty ? "Captured accomplishment" : title
        r.context = note
        r.category = .other
        r.tags = ["quick-capture","needs-review"]
        store.save(r)
        title=""; note=""; saved=true
        DispatchQueue.main.asyncAfter(deadline:.now()+1.5){ saved=false }
    }
}
