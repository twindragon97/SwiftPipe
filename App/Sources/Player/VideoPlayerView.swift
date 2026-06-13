import SwiftUI
import AVKit
import AVFoundation
import SwiftPipeExtractor

/// Resolves a YouTube watch URL to its HLS manifest (via the iOS InnerTube
/// client) and plays it with AVPlayer. This is the Phase 2 milestone screen:
/// search -> tap -> HLS plays.
struct VideoPlayerView: View {
    let item: SearchResultItem

    @StateObject private var loader = StreamLoader()

    var body: some View {
        Group {
            switch loader.state {
            case .idle, .loading:
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .ready(let player):
                VideoPlayer(player: player)
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            case .error(let message):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Could not load video").font(.headline)
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loader.load(item.url) }
    }
}

@MainActor
private final class StreamLoader: ObservableObject {
    enum State {
        case idle
        case loading
        case ready(AVPlayer)
        case error(String)
    }

    @Published private(set) var state: State = .idle

    func load(_ watchUrl: String) async {
        guard case .idle = state else { return }
        state = .loading

        // Use the .playback category so audio plays through the speaker (the
        // default .soloAmbient category doesn't reliably play video audio) and
        // keeps playing when the app is backgrounded.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback)
        try? session.setActive(true)

        let result = await Self.resolveHlsUrl(watchUrl)
        switch result {
        case .success(let hlsUrl):
            // The HLS manifest comes from the iOS InnerTube client, so present
            // the iOS YouTube app User-Agent when AVPlayer fetches it.
            let asset = AVURLAsset(
                url: hlsUrl,
                options: [
                    "AVURLAssetHTTPHeaderFieldsKey": [
                        "User-Agent": Self.iosUserAgent
                    ]
                ])
            let playerItem = AVPlayerItem(asset: asset)
            state = .ready(AVPlayer(playerItem: playerItem))
        case .failure(let error):
            state = .error(error.message)
        }
    }

    private static let iosUserAgent =
        "com.google.ios.youtube/21.03.2(iPhone16,2; U; CPU iOS 18_7_2 like Mac OS X; GB)"

    private static func resolveHlsUrl(
        _ watchUrl: String
    ) async -> Result<URL, AppError> {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let extractor = try ServiceList.YouTube.getStreamExtractor(watchUrl)
                    try extractor.fetchPage()
                    let hls = try extractor.getHlsUrl()
                    guard !hls.isEmpty, let url = URL(string: hls) else {
                        continuation.resume(returning: .failure(
                            AppError("No HLS stream available for this video.")))
                        return
                    }
                    continuation.resume(returning: .success(url))
                } catch {
                    continuation.resume(returning: .failure(AppError(error)))
                }
            }
        }
    }
}
