import Foundation
import AVFoundation
import MediaPlayer
import UIKit

/// Publishes the playing item to the system Now Playing center (lock screen,
/// Control Center) and wires the remote commands (play/pause, ±15s, scrub,
/// next/previous track). Bound once to a reused AVPlayer; call `update` per
/// track and `tearDown()` when leaving.
@MainActor
final class NowPlayingController {
    private let player: AVPlayer
    private let onPrevious: () -> Void
    private let onNext: () -> Void
    private var timeObserver: Any?
    private var artworkTask: Task<Void, Never>?
    private var title = ""
    private var artist = ""

    init(
        player: AVPlayer,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        self.player = player
        self.onPrevious = onPrevious
        self.onNext = onNext
        configureRemoteCommands()
        observePlaybackTime()
    }

    /// Refresh the metadata shown for the current track.
    func update(title: String, artist: String, artworkURL: URL?) {
        self.title = title
        self.artist = artist
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPNowPlayingInfoPropertyPlaybackRate: Double(player.rate),
        ]
        if let duration = player.currentItem?.duration, duration.isNumeric {
            info[MPMediaItemPropertyPlaybackDuration] = duration.seconds
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        loadArtwork(from: artworkURL)
    }

    /// Enable/disable the next/previous commands based on queue position.
    func setQueueCommands(canPrevious: Bool, canNext: Bool) {
        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = canPrevious
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = canNext
    }

    func tearDown() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        artworkTask?.cancel()
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)
        center.skipForwardCommand.removeTarget(nil)
        center.skipBackwardCommand.removeTarget(nil)
        center.changePlaybackPositionCommand.removeTarget(nil)
        center.previousTrackCommand.removeTarget(nil)
        center.nextTrackCommand.removeTarget(nil)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.player.play()
            self?.updatePlaybackState()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.player.pause()
            self?.updatePlaybackState()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            if self.player.rate == 0 {
                self.player.play()
            } else {
                self.player.pause()
            }
            self.updatePlaybackState()
            return .success
        }

        center.skipForwardCommand.preferredIntervals = [15]
        center.skipForwardCommand.addTarget { [weak self] event in
            guard let self,
                  let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            self.seek(by: event.interval)
            return .success
        }
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.addTarget { [weak self] event in
            guard let self,
                  let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            self.seek(by: -event.interval)
            return .success
        }

        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self,
                  let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.player.seek(to: CMTime(seconds: event.positionTime, preferredTimescale: 600))
            self.updatePlaybackState()
            return .success
        }

        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.onPrevious()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.onNext()
            return .success
        }
    }

    private func observePlaybackTime() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.updatePlaybackState() }
        }
    }

    private func updatePlaybackState() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        info[MPNowPlayingInfoPropertyPlaybackRate] = Double(player.rate)
        if let duration = player.currentItem?.duration, duration.isNumeric {
            info[MPMediaItemPropertyPlaybackDuration] = duration.seconds
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func loadArtwork(from url: URL?) {
        artworkTask?.cancel()
        guard let url else { return }
        artworkTask = Task { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data) else { return }
            guard let self, !Task.isCancelled else { return }
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
            info[MPMediaItemPropertyArtwork] = artwork
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    private func seek(by seconds: TimeInterval) {
        let target = player.currentTime().seconds + seconds
        player.seek(to: CMTime(seconds: max(0, target), preferredTimescale: 600))
        updatePlaybackState()
    }
}
