// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/playlist/PlaylistInfoItemExtractor.java @ v0.26.3

public protocol PlaylistInfoItemExtractor: InfoItemExtractor {
    func getUploaderName() throws -> String?
    func getUploaderUrl() throws -> String?
    func isUploaderVerified() throws -> Bool
    func getStreamCount() throws -> Int64
    func getDescription() throws -> Description
    func getPlaylistType() throws -> PlaylistInfo.PlaylistType
}

public extension PlaylistInfoItemExtractor {
    func getDescription() throws -> Description {
        Description.EMPTY_DESCRIPTION
    }

    func getPlaylistType() throws -> PlaylistInfo.PlaylistType {
        .NORMAL
    }
}
