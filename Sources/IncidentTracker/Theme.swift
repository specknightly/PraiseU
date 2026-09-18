import SwiftUI

struct ESTheme {
    static let canvas = Color(red: 0.018, green: 0.055, blue: 0.09)
    static let sidebar = Color(red: 0.025, green: 0.075, blue: 0.12)
    static let panel = Color(red: 0.035, green: 0.09, blue: 0.14)
    static let panelRaised = Color(red: 0.055, green: 0.12, blue: 0.18)
    static let field = Color(red: 0.065, green: 0.13, blue: 0.19)
    static let border = Color.white.opacity(0.09)
    static let muted = Color.white.opacity(0.66)
    static let accent = Color(red: 0.0, green: 0.43, blue: 0.96)
    static let gold = Color(red: 1.0, green: 0.73, blue: 0.18)
    static let danger = Color(red: 0.92, green: 0.28, blue: 0.25)
}

struct PanelBackground: ViewModifier {
    var radius: CGFloat = 12
    func body(content: Content) -> some View {
        content
            .background(ESTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(ESTheme.border))
    }
}

extension View {
    func panelBackground(radius: CGFloat = 12) -> some View {
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
            .stroke(.white, style: StrokeStyle(lineWidth: max(2, w * 0.025), lineJoin: .round))

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
