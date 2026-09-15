import SwiftUI

/// Shown once, before the main window becomes usable, gated by `hasAcknowledgedDisclaimer` in
/// RootView. Most users never read a GitHub README — this is the surface that actually reaches them.
struct DisclaimerGateView: View {
    let onAcknowledge: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Before You Start", systemImage: "exclamationmark.shield")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.entropyShieldGold)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    paragraph("This software is provided \u{201c}AS IS,\u{201d} without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement. Use it at your own risk.")
                    paragraph("The developer makes no guarantee that this app is free of bugs, data loss, or other defects, and is not liable for any damages, data loss, misuse, or other consequences \u{2014} direct, indirect, incidental, or otherwise \u{2014} arising from the use of, or inability to use, this software.")
                    paragraph("You are solely responsible for what you choose to record in this app, including any sensitive, personal, proprietary, or confidential information. Accomplishment Tracker does not review, filter, or restrict what you type, attach, or import \u{2014} that judgment call is yours alone, every time.")
                    paragraph("Before recording work-related information, follow your employer's data-handling policies and any applicable laws or regulations in your jurisdiction. When in doubt, don't record it here.")
                    Text("Full terms: LICENSE (MIT) and the Disclaimer section of README.md.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.trailing, 4)
            }
            .frame(maxHeight: 260)

            Button("I Understand and Agree") { onAcknowledge() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(28)
        .frame(width: 480)
        .entropyShieldBackdrop()
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(Color.entropyShieldText.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true)
    }
}
