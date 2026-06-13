import Foundation
import AVFoundation
import MediaPlayer
import UIKit

/// Publishes the playing item to the system Now Playing center (lock screen,
/// Control Center) and wires the remote commands (play/pause, ±15s, scrub).
/// Owned by the player screen; call `tearDown()` when leaving.
@MainActor
final class NowPlayingController {
    private let player: AVPlayer
    private let title: String
    private let artist: String
    private var timeObserver: Any?
    private var artworkTask: Task<Void, Never>?

    init(player: AVPlayer, title: String, artist: String, artworkURL: URL?) {
        self.player = player
        self.title = title
        self.artist = artist

        setInitialInfo()
        configureRemoteCommands()
        observePlaybackTime()
        loadArtwork(from: artworkURL)
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
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func setInitialInfo() {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPNowPlayingInfoPropertyPlaybackRate: Double(player.rate),
        ]
        if let duration = player.currentItem?.duration, duration.isNumeric {
            info[MPMediaItemPropertyPlaybackDuration] = duration.seconds
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
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
    }

    private func observePlaybackTime() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self] _ in
            // The closure is delivered on the main queue; hop onto the main
            // actor to touch the actor-isolated player/state.
            Task { @MainActor in self?.updatePlaybackState() }
        }
    }

    private func updatePlaybackState() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] =
            player.currentTime().seconds
        info[MPNowPlayingInfoPropertyPlaybackRate] = Double(player.rate)
        if let duration = player.currentItem?.duration, duration.isNumeric {
            info[MPMediaItemPropertyPlaybackDuration] = duration.seconds
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func loadArtwork(from url: URL?) {
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
