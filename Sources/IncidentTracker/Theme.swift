import SwiftUI

struct ESTheme {
    // Dark-only palette inspired by modern financial/operations dashboards.
    // Surfaces stay neutral charcoal so the career evidence remains the visual focus.
    static let canvas = Color(red: 0.024, green: 0.025, blue: 0.030)
    static let sidebar = Color(red: 0.038, green: 0.039, blue: 0.047)
    static let panel = Color(red: 0.055, green: 0.056, blue: 0.066)
    static let panelRaised = Color(red: 0.074, green: 0.075, blue: 0.087)
    static let field = Color(red: 0.088, green: 0.089, blue: 0.102)

    static let textPrimary = Color(red: 0.95, green: 0.94, blue: 0.91)
    static let muted = Color(red: 0.69, green: 0.69, blue: 0.71)

    // Matte gold is the sole primary accent family.
    static let accent = Color(red: 0.70, green: 0.60, blue: 0.39)
    static let gold = Color(red: 0.84, green: 0.77, blue: 0.60)
    static let goldSoft = Color(red: 0.76, green: 0.68, blue: 0.51)
    static let onAccent = Color(red: 0.075, green: 0.068, blue: 0.052)

    static let border = gold.opacity(0.14)
    static let borderStrong = gold.opacity(0.28)
    static let selection = gold.opacity(0.13)
    static let selectionHover = gold.opacity(0.08)

    static let danger = Color(red: 0.86, green: 0.34, blue: 0.31)

    static let panelGradient = LinearGradient(
        colors: [
            Color(red: 0.075, green: 0.076, blue: 0.088),
            Color(red: 0.052, green: 0.053, blue: 0.062)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let canvasGradient = LinearGradient(
        colors: [
            Color(red: 0.031, green: 0.032, blue: 0.038),
            canvas
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct PanelBackground: ViewModifier {
    var radius: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .background(ESTheme.panelGradient)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(ESTheme.border)
            )
            .shadow(color: .black.opacity(0.22), radius: 12, x: 0, y: 5)
    }
}

extension View {
    func panelBackground(radius: CGFloat = 14) -> some View {
        modifier(PanelBackground(radius: radius))
    }
}

struct EntropyShieldMark: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            Path { path in
                let points = [
                    CGPoint(x: w * 0.5, y: h * 0.04),
                    CGPoint(x: w * 0.9, y: h * 0.27),
                    CGPoint(x: w * 0.9, y: h * 0.73),
                    CGPoint(x: w * 0.5, y: h * 0.96),
                    CGPoint(x: w * 0.1, y: h * 0.73),
                    CGPoint(x: w * 0.1, y: h * 0.27)
                ]
                path.move(to: points[0])
                for p in points.dropFirst() { path.addLine(to: p) }
                path.closeSubpath()
            }
            .stroke(ESTheme.textPrimary.opacity(0.82), style: StrokeStyle(lineWidth: max(2, w * 0.025), lineJoin: .round))

            Path { path in
                let center = CGPoint(x: w * 0.5, y: h * 0.55)
                path.move(to: center)
                path.addLine(to: CGPoint(x: w * 0.28, y: h * 0.39))
                path.move(to: center)
                path.addLine(to: CGPoint(x: w * 0.73, y: h * 0.34))
            }
            .stroke(ESTheme.gold, style: StrokeStyle(lineWidth: max(2, w * 0.025), lineCap: .round))
        }
    }
}
