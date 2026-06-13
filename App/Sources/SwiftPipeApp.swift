import SwiftUI
import SwiftPipeExtractor

@main
struct SwiftPipeApp: App {
    init() {
        Self.bootstrapExtractor()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    /// Wires the extractor to the app's downloader and enables the iOS
    /// InnerTube client so stream extraction yields the HLS manifest that
    /// AVPlayer can play natively.
    ///
    /// The JavaScriptCore runner is not wired yet: signature/throttling
    /// deciphering (needed only for progressive/DASH stream URLs) is deferred,
    /// and the iOS-client HLS manifest needs no JS.
    private static func bootstrapExtractor() {
        NewPipe.initialize(
            DownloaderImpl.shared,
            Localization("en", "GB"),
            ContentCountry("GB"))
        YoutubeStreamExtractor.setFetchIosClient(true)
    }
}
