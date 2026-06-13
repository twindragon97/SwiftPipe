// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/playlist/PlaylistInfoItem.java @ v0.26.3

public final class PlaylistInfoItem: InfoItem {
    private var uploaderName: String?
    private var uploaderUrl: String?
    private var uploaderVerified = false
    private var streamCount: Int64 = 0
    private var description: Description?
    private var playlistType: PlaylistInfo.PlaylistType?

    public init(_ serviceId: Int, _ url: String, _ name: String) {
        super.init(.PLAYLIST, serviceId, url, name)
    }

    public func getUploaderName() -> String? { uploaderName }
    public func setUploaderName(_ uploaderName: String?) { self.uploaderName = uploaderName }

    public func getUploaderUrl() -> String? { uploaderUrl }
    public func setUploaderUrl(_ uploaderUrl: String?) { self.uploaderUrl = uploaderUrl }

    public func isUploaderVerified() -> Bool { uploaderVerified }
    public func setUploaderVerified(_ uploaderVerified: Bool) {
        self.uploaderVerified = uploaderVerified
    }

    public func getStreamCount() -> Int64 { streamCount }
    public func setStreamCount(_ streamCount: Int64) { self.streamCount = streamCount }

    public func getDescription() -> Description? { description }
    public func setDescription(_ description: Description?) { self.description = description }

    public func getPlaylistType() -> PlaylistInfo.PlaylistType? { playlistType }
    public func setPlaylistType(_ playlistType: PlaylistInfo.PlaylistType?) {
        self.playlistType = playlistType
    }
}
