// Mirrors: app/src/main/java/org/schabi/newpipe/database/playlist/dao/PlaylistDAO.kt @ v0.27.x

import GRDB

public struct PlaylistDAO {
    let dbWriter: DatabaseWriter

    public init(_ dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    // MARK: Queries

    public func getAll(_ db: Database) throws -> [PlaylistEntity] {
        try PlaylistEntity.fetchAll(db, sql: "SELECT * FROM playlists")
    }

    public func getPlaylist(_ db: Database, playlistId: Int64) throws -> PlaylistEntity? {
        try PlaylistEntity.fetchOne(db, sql: "SELECT * FROM playlists WHERE uid = ?", arguments: [playlistId])
    }

    public func count(_ db: Database) throws -> Int64 {
        try Int64.fetchOne(db, sql: "SELECT COUNT(*) FROM playlists") ?? 0
    }

    @discardableResult
    public func insert(_ db: Database, _ playlist: PlaylistEntity) throws -> Int64 {
        var playlist = playlist
        try playlist.insert(db)
        return playlist.uid
    }

    public func update(_ db: Database, _ playlist: PlaylistEntity) throws {
        try playlist.update(db)
    }

    @discardableResult
    public func deletePlaylist(_ db: Database, playlistId: Int64) throws -> Int {
        try db.execute(sql: "DELETE FROM playlists WHERE uid = ?", arguments: [playlistId])
        return db.changesCount
    }

    /// Mirror of upsertPlaylist: insert when unsaved, otherwise update in place.
    @discardableResult
    public func upsertPlaylist(_ db: Database, _ playlist: PlaylistEntity) throws -> Int64 {
        if playlist.uid == 0 || playlist.uid == -1 {
            return try insert(db, playlist)
        }
        try update(db, playlist)
        return playlist.uid
    }

    // MARK: Convenience wrappers

    public func getAll() throws -> [PlaylistEntity] {
        try dbWriter.read { db in try getAll(db) }
    }

    @discardableResult
    public func insert(_ playlist: PlaylistEntity) throws -> Int64 {
        try dbWriter.write { db in try insert(db, playlist) }
    }

    @discardableResult
    public func deletePlaylist(playlistId: Int64) throws -> Int {
        try dbWriter.write { db in try deletePlaylist(db, playlistId: playlistId) }
    }
}
