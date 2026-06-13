// Mirrors: app/src/main/java/org/schabi/newpipe/database/playlist/model/PlaylistStreamEntity.kt @ v0.27.x

import GRDB

public struct PlaylistStreamEntity: FetchableRecord, MutablePersistableRecord, Equatable {
    public static let databaseTableName = "playlist_stream_join"

    public var playlistUid: Int64
    public var streamUid: Int64
    /// Position within the playlist (column `join_index`).
    public var index: Int

    public init(playlistUid: Int64, streamUid: Int64, index: Int) {
        self.playlistUid = playlistUid
        self.streamUid = streamUid
        self.index = index
    }

    public init(row: Row) {
        playlistUid = row["playlist_id"]
        streamUid = row["stream_id"]
        index = row["join_index"]
    }

    public func encode(to container: inout PersistenceContainer) {
        container["playlist_id"] = playlistUid
        container["stream_id"] = streamUid
        container["join_index"] = index
    }
}
