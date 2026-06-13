import Foundation
import AVFoundation
import SwiftPipeExtractor

/// Drives playback through a queue of search results: one reused AVPlayer
/// whose current item is replaced as the queue advances, autoplay on
/// end-of-item, and next/previous navigation (also exposed to the lock screen
/// via NowPlayingController).
@MainActor
final class QueuePlayerModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case playing
        case error(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.playing, .playing):
                return true
            case (.error(let a), .error(let b)):
                return a == b
            default:
                return false
            }
        }
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var currentTitle = ""
    @Published private(set) var quality: StreamQuality = .auto

    let player = AVPlayer()

    private var items: [SearchResultItem] = []
    private var index = 0
    private var nowPlaying: NowPlayingController?
    private var endObserver: NSObjectProtocol?
    private var loadToken = 0

    func start(_ request: PlaybackRequest) {
        guard case .idle = state else { return }
        items = request.items
        index = min(max(request.index, 0), max(items.count - 1, 0))

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback)
        try? session.setActive(true)

        nowPlaying = NowPlayingController(
            player: player,
            onPrevious: { [weak self] in self?.previous() },
            onNext: { [weak self] in self?.next() })

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] note in
            let endedItem = note.object as? AVPlayerItem
            Task { @MainActor in
                guard let self, endedItem === self.player.currentItem else { return }
                self.next()
            }
        }

        loadCurrent()
    }

    func next() {
        guard index + 1 < items.count else { return }
        index += 1
        loadCurrent()
    }

    func previous() {
        guard index - 1 >= 0 else { return }
        index -= 1
        loadCurrent()
    }

    /// Caps the HLS adaptive resolution for the current item and any future
    /// queue items.
    func setQuality(_ quality: StreamQuality) {
        self.quality = quality
        player.currentItem?.preferredMaximumResolution = quality.maxResolution
    }

    // Cleanup runs in deinit (when the view is truly popped) rather than in
    // onDisappear: AVPlayerViewController's fullscreen presentation makes
    // SwiftUI fire onDisappear on the underlying view, and tearing the player
    // down there left a black screen on return. deinit only fires when the
    // @StateObject is actually released.
    deinit {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        player.pause()
        let nowPlaying = self.nowPlaying
        Task { @MainActor in
            nowPlaying?.tearDown()
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }

    private func loadCurrent() {
        guard items.indices.contains(index) else { return }
        let item = items[index]
        currentTitle = item.title
        state = .loading
        nowPlaying?.update(
            title: item.title, artist: item.uploader, artworkURL: item.thumbnailURL)
        nowPlaying?.setQueueCommands(
            canPrevious: index > 0, canNext: index + 1 < items.count)

        loadToken += 1
        let token = loadToken

        Task { [weak self] in
            let result = await Self.resolveHlsUrl(item.url)
            guard let self, token == self.loadToken else { return }
            switch result {
            case .success(let url):
                let asset = AVURLAsset(
                    url: url,
                    options: [
                        "AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": Self.iosUserAgent]
                    ])
                let playerItem = AVPlayerItem(asset: asset)
                playerItem.preferredMaximumResolution = self.quality.maxResolution
                self.player.replaceCurrentItem(with: playerItem)
                self.player.play()
                self.state = .playing
            case .failure(let error):
                self.state = .error(error.message)
            }
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
