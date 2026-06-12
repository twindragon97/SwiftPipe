import SwiftUI
import SwiftPipeExtractor
import SwiftPipeExtractorJS

/// Phase 0 bootstrap screen. Verifies on-device that the app launches, that
/// the SPM packages link, and that the JavaScriptCore seam (Rhino replacement)
/// works. Replaced by the real UI from Phase 2 onwards.
struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var jsCheckResult = "running…"

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.rectangle.on.rectangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)

            Text("SwiftPipe")
                .font(.largeTitle.bold())

            Text("Phase 0 — bootstrap build")
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Label(
                    horizontalSizeClass == .regular
                        ? "Regular width (iPad / landscape)"
                        : "Compact width (iPhone)",
                    systemImage: horizontalSizeClass == .regular
                        ? "ipad.landscape"
                        : "iphone"
                )
                Label("JavaScriptCore: \(jsCheckResult)", systemImage: "curlybraces")
            }
            .font(.footnote.monospaced())
            .foregroundStyle(.secondary)
        }
        .padding()
        .onAppear(perform: runJavaScriptSelfCheck)
    }

    private func runJavaScriptSelfCheck() {
        do {
            let result = try JavaScriptCoreRunner().run(
                function: "function check(x) { return x + '-ok'; }",
                functionName: "check",
                parameters: ["jsc"]
            )
            jsCheckResult = result == "jsc-ok" ? "OK" : "unexpected: \(result)"
        } catch {
            jsCheckResult = "failed: \(error)"
        }
    }
}

#Preview {
    ContentView()
}
