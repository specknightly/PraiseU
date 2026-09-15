import SwiftUI

/// Entropy Shield house style: deep navy backgrounds with muted gold text/accents, matching the
/// rest of the Entropy Shield app suite. Centralized here so every screen stays consistent.
enum EntropyShieldTheme {
    static let navy = Color(red: 0.043, green: 0.067, blue: 0.145)
    static let navySurface = Color(red: 0.075, green: 0.105, blue: 0.20)
    static let navySurfaceElevated = Color(red: 0.11, green: 0.145, blue: 0.245)

    static let gold = Color(red: 0.84, green: 0.72, blue: 0.42)
    static let goldMuted = Color(red: 0.84, green: 0.72, blue: 0.42).opacity(0.72)
    static let goldFaint = Color(red: 0.84, green: 0.72, blue: 0.42).opacity(0.45)
    /// Body copy — long free-text stays legible instead of being set entirely in gold.
    static let textPrimary = Color(red: 0.93, green: 0.91, blue: 0.86)
}

extension Color {
    static let entropyShieldNavy = EntropyShieldTheme.navy
    static let entropyShieldNavySurface = EntropyShieldTheme.navySurface
    static let entropyShieldNavySurfaceElevated = EntropyShieldTheme.navySurfaceElevated
    static let entropyShieldGold = EntropyShieldTheme.gold
    static let entropyShieldGoldMuted = EntropyShieldTheme.goldMuted
    static let entropyShieldGoldFaint = EntropyShieldTheme.goldFaint
    static let entropyShieldText = EntropyShieldTheme.textPrimary
}

/// Screen-level backdrop. Reads the "Transparent Glass" setting so every screen responds to the
/// same toggle without each view re-implementing the branch.
struct EntropyShieldBackdrop: ViewModifier {
    @AppStorage("useGlassEffect") private var useGlassEffect = false

    func body(content: Content) -> some View {
        content.background {
            if useGlassEffect {
                Rectangle().fill(.ultraThinMaterial)
            } else {
                Rectangle().fill(EntropyShieldTheme.navy)
            }
        }
    }
}

/// Card/panel-level surface — one step lighter than the screen backdrop so cards read as raised.
struct EntropyShieldSurface: ViewModifier {
    @AppStorage("useGlassEffect") private var useGlassEffect = false
    var cornerRadius: CGFloat = 14
    var elevated: Bool = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        // No stroke: a filled surface reads as a raised panel on its own. Bordering every panel
        // on top of that is what made the app feel boxed-in everywhere.
        return content
            .background {
                if useGlassEffect {
                    shape.fill(.ultraThinMaterial)
                } else {
                    shape.fill(elevated ? EntropyShieldTheme.navySurfaceElevated : EntropyShieldTheme.navySurface)
                }
            }
    }
}

extension View {
    /// Full-screen backdrop for a window/pane's root content.
    func entropyShieldBackdrop() -> some View {
        modifier(EntropyShieldBackdrop())
    }

    /// A card/panel surface (settings sections, metric tiles, editor panels).
    func entropyShieldSurface(cornerRadius: CGFloat = 14, elevated: Bool = false) -> some View {
        modifier(EntropyShieldSurface(cornerRadius: cornerRadius, elevated: elevated))
    }
}
