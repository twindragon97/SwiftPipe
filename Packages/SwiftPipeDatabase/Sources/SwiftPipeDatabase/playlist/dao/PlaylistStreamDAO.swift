// Mirrors: app/src/main/java/org/schabi/newpipe/database/playlist/dao/PlaylistStreamDAO.kt @ v0.27.x

import GRDB

public struct PlaylistStreamDAO {
    let dbWriter: DatabaseWriter

    public init(_ dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    // MARK: Queries

    @discardableResult
    public func deleteBatch(_ db: Database, playlistId: Int64) throws -> Int {
        try db.execute(sql: "DELETE FROM playlist_stream_join WHERE playlist_id = ?", arguments: [playlistId])
        return db.changesCount
    }

    /// Highest join_index currently in the playlist, or -1 when empty.
    public func getMaximumIndexOf(_ db: Database, playlistId: Int64) throws -> Int {
        try Int.fetchOne(
            db,
            sql: "SELECT COALESCE(MAX(join_index), -1) FROM playlist_stream_join WHERE playlist_id = ?",
            arguments: [playlistId]) ?? -1
    }

    /// Stream id to use as the automatic playlist thumbnail (first stream), or
    /// PlaylistEntity.defaultThumbnailId (-1) when the playlist is empty.
    public func getAutomaticThumbnailStreamId(_ db: Database, playlistId: Int64) throws -> Int64 {
        try Int64.fetchOne(db, sql: """
            SELECT CASE WHEN COUNT(*) != 0 THEN stream_id ELSE \(PlaylistEntity.defaultThumbnailId) END
            FROM streams
            LEFT JOIN playlist_stream_join ON uid = stream_id
            WHERE playlist_id = ? LIMIT 1
            """, arguments: [playlistId]) ?? PlaylistEntity.defaultThumbnailId
    }

    /// Streams of a playlist in playlist order, joined with resume positions.
    public func getOrderedStreamsOf(_ db: Database, playlistId: Int64) throws -> [PlaylistStreamEntry] {
        try PlaylistStreamEntry.fetchAll(db, sql: """
            SELECT * FROM streams
            INNER JOIN (SELECT stream_id, join_index FROM playlist_stream_join WHERE playlist_id = ?)
            ON uid = stream_id
            LEFT JOIN (SELECT stream_id AS stream_id_alias, progress_time FROM stream_state)
            ON uid = stream_id_alias
            ORDER BY join_index ASC
            """, arguments: [playlistId])
    }

    /// Local-playlist list with derived thumbnail and stream count, ordered by
    /// display_index. Uses a LEFT JOIN so empty playlists still appear (with
    /// streamCount 0). Mirror of getPlaylistMetadata.
    public func getPlaylistMetadata(_ db: Database) throws -> [PlaylistMetadataEntry] {
        try PlaylistMetadataEntry.fetchAll(db, sql: """
            SELECT uid, name, is_thumbnail_permanent, thumbnail_stream_id, display_index,
            (SELECT thumbnail_url FROM streams WHERE streams.uid = thumbnail_stream_id) AS thumbnail_url,
            COALESCE(COUNT(playlist_id), 0) AS streamCount FROM playlists
            LEFT JOIN playlist_stream_join ON playlists.uid = playlist_id
            GROUP BY uid
            ORDER BY display_index
            """)
    }

    public func insert(_ db: Database, _ entity: PlaylistStreamEntity) throws {
        var entity = entity
        try entity.insert(db)
    }

    public func insertAll(_ db: Database, _ entities: [PlaylistStreamEntity]) throws {
        for entity in entities {
            var entity = entity
            try entity.insert(db)
        }
    }

    // MARK: Convenience wrappers

    public func getPlaylistMetadata() throws -> [PlaylistMetadataEntry] {
        try dbWriter.read { db in try getPlaylistMetadata(db) }
    }

    public func getOrderedStreamsOf(playlistId: Int64) throws -> [PlaylistStreamEntry] {
        try dbWriter.read { db in try getOrderedStreamsOf(db, playlistId: playlistId) }
    }
}
