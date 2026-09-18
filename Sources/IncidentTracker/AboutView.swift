import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing:18) {
            if let url = Bundle.main.url(forResource: "EntropyShieldLogo", withExtension: "png"), let image = NSImage(contentsOf: url) { Image(nsImage:image).resizable().scaledToFit().frame(width:110,height:110) }
            else { EntropyShieldMark().frame(width:110,height:110) }
            Text("Entropy Shield Work Record").font(.system(size:28,weight:.bold))
            Text("Promotion Evidence + CYA Incident Record").font(.title3).foregroundStyle(ESTheme.gold)
            Text("A local-first career evidence vault: prove the wins that support promotion, and preserve detailed factual records when uncomfortable incidents need to be explained later.")
                .multilineTextAlignment(.center).foregroundStyle(ESTheme.muted).frame(maxWidth:500)
            Divider().overlay(ESTheme.border)
            VStack(spacing:4) {
                Text("Developed by").foregroundStyle(ESTheme.muted)
                Text("Peter Odintsov").font(.title3.bold())
                Text("Version 2.0.0").font(.caption).foregroundStyle(ESTheme.muted)
            }
        }.padding(34).frame(width:620,height:470).background(ESTheme.canvasGradient).foregroundStyle(ESTheme.textPrimary)
    }
}
