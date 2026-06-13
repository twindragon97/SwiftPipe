import Foundation
import AVFoundation
import SwiftPipeExtractor
import SwiftPipeDatabase

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
    private var progressObserver: Any?
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

        // Persist the resume position every few seconds so playback can continue
        // where it left off (and so finished videos get marked as such).
        progressObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 5, preferredTimescale: 1), queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                guard let self, self.items.indices.contains(self.index) else { return }
                guard time.seconds.isFinite else { return }
                let item = self.items[self.index]
                let millis = Int64(time.seconds * 1000)
                guard millis > 0 else { return }
                Self.saveProgress(item: item, millis: millis)
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
        if let progressObserver {
            player.removeTimeObserver(progressObserver)
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
            let result = await Self.prepare(item)
            guard let self, token == self.loadToken else { return }
            switch result {
            case .success(let resolved):
                let asset = AVURLAsset(
                    url: resolved.url,
                    options: [
                        "AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": Self.iosUserAgent]
                    ])
                let playerItem = AVPlayerItem(asset: asset)
                playerItem.preferredMaximumResolution = self.quality.maxResolution
                self.player.replaceCurrentItem(with: playerItem)
                if let resumeMillis = resolved.resumeMillis, resumeMillis > 0 {
                    // Completion-handler overload: avoids the async seek variant
                    // (we're in an async context) and returns immediately.
                    self.player.seek(
                        to: CMTime(value: resumeMillis, timescale: 1000),
                        toleranceBefore: .zero, toleranceAfter: .zero) { _ in }
                }
                self.player.play()
                self.state = .playing
            case .failure(let error):
                self.state = .error(error.message)
            }
        }
    }

    /// Saves the resume position for an item. Fire-and-forget on a background
    /// task; HistoryRecordManager only persists it when it crosses the validity
    /// threshold.
    private static func saveProgress(item: SearchResultItem, millis: Int64) {
        Task.detached(priority: .utility) {
            try? Library.shared.history.saveStreamState(
                StreamEntity(item: item), progressMillis: millis)
        }
    }

    private static let iosUserAgent =
        "com.google.ios.youtube/21.03.2(iPhone16,2; U; CPU iOS 18_7_2 like Mac OS X; GB)"

    private struct Resolved {
        let url: URL
        let resumeMillis: Int64?
    }

    /// Resolves the HLS manifest, records the view in watch history, and returns
    /// any saved resume position — all off the main thread.
    private static func prepare(_ item: SearchResultItem) async -> Result<Resolved, AppError> {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let extractor = try ServiceList.YouTube.getStreamExtractor(item.url)
                    try extractor.fetchPage()
                    let hls = try extractor.getHlsUrl()
                    guard !hls.isEmpty, let url = URL(string: hls) else {
                        continuation.resume(returning: .failure(
                            AppError("No HLS stream available for this video.")))
                        return
                    }

                    // Record the view and look up a resume position.
                    var resumeMillis: Int64?
                    let stream = StreamEntity(item: item)
                    if let streamId = try? Library.shared.history.onViewed(stream) {
                        resumeMillis = (try? Library.shared.history.loadStreamState(
                            streamId: streamId, durationInSeconds: item.durationSeconds))?.progressMillis
                    }

                    continuation.resume(returning: .success(
                        Resolved(url: url, resumeMillis: resumeMillis)))
                } catch {
                    continuation.resume(returning: .failure(AppError(error)))
                }
            }
        }
    }
}
