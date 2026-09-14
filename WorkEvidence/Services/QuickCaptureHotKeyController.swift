import AppKit
import Carbon.HIToolbox
import SwiftUI
import SwiftData

/// A system-wide keyboard shortcut (⌃⌥A) that opens Quick Capture from anywhere, without switching
/// away from whatever app is currently frontmost.
///
/// SwiftUI's `MenuBarExtra` has no public API to open its popover programmatically, so a hotkey can't
/// just "click" it. Instead this shows the same `QuickCaptureView` in a small floating `NSPanel` —
/// the same pattern Spotlight-style quick-entry tools use. `RegisterEventHotKey` (Carbon) is used
/// rather than a global `NSEvent` monitor because it registers one specific key combo instead of
/// observing all keystrokes, which is the appropriate scope for a sandboxed app and needs no
/// Accessibility/Input Monitoring permission.
@MainActor
final class QuickCaptureHotKeyController {
    static let shared = QuickCaptureHotKeyController()

    /// Control+Option+A. Chosen to avoid colliding with common system shortcuts (Cmd-based) and
    /// common app shortcuts, while still being one-handed and easy to remember ("A" for Accomplishment).
    private static let keyCode = UInt32(kVK_ANSI_A)
    private static let modifiers = UInt32(controlKey | optionKey)
    private static let signature: OSType = 0x51434150 // 'QCAP'

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var panel: NSPanel?
    private var modelContainer: ModelContainer?

    private init() {}

    func activate(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        guard hotKeyRef == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            QuickCaptureHotKeyController.shared.toggle()
            return noErr
        }, 1, &eventType, nil, &eventHandlerRef)

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: 1)
        RegisterEventHotKey(Self.keyCode, Self.modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func toggle() {
        if let panel, panel.isVisible {
            panel.orderOut(nil)
        } else {
            show()
        }
    }

    private func show() {
        guard let modelContainer else { return }
        let panel = self.panel ?? makePanel(modelContainer: modelContainer)
        self.panel = panel
        positionNearMouse(panel)
        panel.makeKeyAndOrderFront(nil)
    }

    private func makePanel(modelContainer: ModelContainer) -> NSPanel {
        let hosting = NSHostingController(
            rootView: QuickCaptureView(onRequestClose: { [weak self] in self?.panel?.orderOut(nil) })
                .modelContainer(modelContainer)
        )
        let panel = QuickCapturePanel(contentViewController: hosting)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.styleMask.insert(.nonactivatingPanel)
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true

        NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: panel, queue: .main) { [weak panel] _ in
            panel?.orderOut(nil)
        }

        return panel
    }

    private func positionNearMouse(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main
        let frame = panel.frame
        var origin = CGPoint(x: mouse.x - frame.width / 2, y: mouse.y - frame.height - 12)
        if let visible = screen?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX), visible.maxX - frame.width)
            origin.y = min(max(origin.y, visible.minY), visible.maxY - frame.height)
        }
        panel.setFrameOrigin(origin)
    }
}

/// A borderless panel that can still become key so its TextField/TextEditor accept keystrokes,
/// which `NSPanel` does not allow by default.
private final class QuickCapturePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}
