// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/playlist/PlaylistExtractor.java @ v0.26.3

open class PlaylistExtractor: ListExtractor<StreamInfoItem> {
    public override init(_ service: StreamingService, _ linkHandler: ListLinkHandler) {
        super.init(service, linkHandler)
    }

    open func getUploaderUrl() throws -> String {
        preconditionFailure("PlaylistExtractor.getUploaderUrl must be overridden")
    }

    open func getUploaderName() throws -> String {
        preconditionFailure("PlaylistExtractor.getUploaderName must be overridden")
    }

    open func getUploaderAvatars() throws -> [Image] {
        preconditionFailure("PlaylistExtractor.getUploaderAvatars must be overridden")
    }

    open func isUploaderVerified() throws -> Bool {
        preconditionFailure("PlaylistExtractor.isUploaderVerified must be overridden")
    }

    open func getStreamCount() throws -> Int64 {
        preconditionFailure("PlaylistExtractor.getStreamCount must be overridden")
    }

    open func getDescription() throws -> Description {
        preconditionFailure("PlaylistExtractor.getDescription must be overridden")
    }

    open func getThumbnails() throws -> [Image] {
        []
    }

    open func getBanners() throws -> [Image] {
        []
    }

    open func getSubChannelName() throws -> String {
        ""
    }

    open func getSubChannelUrl() throws -> String {
        ""
    }

    open func getSubChannelAvatars() throws -> [Image] {
        []
    }

    open func getPlaylistType() throws -> PlaylistInfo.PlaylistType {
        .NORMAL
    }
}
