// Mirrors: app/src/main/java/org/schabi/newpipe/local/playlist/LocalPlaylistManager.java @ v0.27.x
//
// Coordinates the three playlist-related DAOs inside single transactions, just
// like the Android manager. RxJava (Maybe/Completable/Flowable, Schedulers.io)
// becomes synchronous throwing methods; the app calls these off the main actor.

import GRDB

public final class LocalPlaylistManager {
    /// Sentinel meaning "do not touch the thumbnail" in modifyPlaylist.
    private static let thumbnailIdLeaveUnchanged: Int64 = -2

    private let dbWriter: DatabaseWriter
    private let streamTable: StreamDAO
    private let playlistTable: PlaylistDAO
    private let playlistStreamTable: PlaylistStreamDAO

    public init(_ database: NewPipeDatabase) {
        dbWriter = database.dbWriter
        streamTable = database.streamDAO
        playlistTable = database.playlistDAO
        playlistStreamTable = database.playlistStreamDAO
    }

    /// Creates a playlist from a non-empty stream list, placed at the top of the
    /// bookmark list (display_index = -1). Returns the new playlist uid, or nil
    /// when `streams` is empty (mirror of the Maybe.empty() guard).
    @discardableResult
    public func createPlaylist(name: String, streams: [StreamEntity]) throws -> Int64? {
        guard !streams.isEmpty else { return nil }
        return try dbWriter.write { db in
            let streamIds = try streamTable.upsertAll(db, streams)
            let newPlaylist = PlaylistEntity(
                name: name, isThumbnailPermanent: false,
                thumbnailStreamId: streamIds[0], displayIndex: -1)
            let playlistId = try playlistTable.insert(db, newPlaylist)
            try insertJoinEntities(db, playlistId: playlistId, streamIds: streamIds, indexOffset: 0)
            return playlistId
        }
    }

    /// Appends streams after the current maximum join index.
    public func appendToPlaylist(playlistId: Int64, streams: [StreamEntity]) throws {
        try dbWriter.write { db in
            let maxJoinIndex = try playlistStreamTable.getMaximumIndexOf(db, playlistId: playlistId)
            let streamIds = try streamTable.upsertAll(db, streams)
            try insertJoinEntities(
                db, playlistId: playlistId, streamIds: streamIds, indexOffset: maxJoinIndex + 1)
        }
    }

    private func insertJoinEntities(
        _ db: Database, playlistId: Int64, streamIds: [Int64], indexOffset: Int
    ) throws {
        let joins = streamIds.enumerated().map { index, streamId in
            PlaylistStreamEntity(playlistUid: playlistId, streamUid: streamId, index: index + indexOffset)
        }
        try playlistStreamTable.insertAll(db, joins)
    }

    /// Replaces a playlist's stream order (reorder/remove). Mirror of updateJoin.
    public func updateJoin(playlistId: Int64, streamIds: [Int64]) throws {
        try dbWriter.write { db in
            try playlistStreamTable.deleteBatch(db, playlistId: playlistId)
            let joins = streamIds.enumerated().map { index, streamId in
                PlaylistStreamEntity(playlistUid: playlistId, streamUid: streamId, index: index)
            }
            try playlistStreamTable.insertAll(db, joins)
        }
    }

    public func getPlaylists() throws -> [PlaylistMetadataEntry] {
        try playlistStreamTable.getPlaylistMetadata()
    }

    public func getPlaylistStreams(playlistId: Int64) throws -> [PlaylistStreamEntry] {
        try playlistStreamTable.getOrderedStreamsOf(playlistId: playlistId)
    }

    @discardableResult
    public func renamePlaylist(playlistId: Int64, name: String) throws -> Bool {
        try modifyPlaylist(
            playlistId: playlistId, name: name,
            thumbnailStreamId: Self.thumbnailIdLeaveUnchanged, isPermanent: false)
    }

    @discardableResult
    public func changePlaylistThumbnail(
        playlistId: Int64, thumbnailStreamId: Int64, isPermanent: Bool
    ) throws -> Bool {
        try modifyPlaylist(
            playlistId: playlistId, name: nil,
            thumbnailStreamId: thumbnailStreamId, isPermanent: isPermanent)
    }

    @discardableResult
    public func deletePlaylist(playlistId: Int64) throws -> Int {
        try playlistTable.deletePlaylist(playlistId: playlistId)
    }

    public func hasPlaylists() throws -> Bool {
        try dbWriter.read { db in try playlistTable.count(db) > 0 }
    }

    @discardableResult
    private func modifyPlaylist(
        playlistId: Int64, name: String?, thumbnailStreamId: Int64, isPermanent: Bool
    ) throws -> Bool {
        try dbWriter.write { db in
            guard var playlist = try playlistTable.getPlaylist(db, playlistId: playlistId) else {
                return false
            }
            if let name { playlist.name = name }
            if thumbnailStreamId != Self.thumbnailIdLeaveUnchanged {
                playlist.thumbnailStreamId = thumbnailStreamId
                playlist.isThumbnailPermanent = isPermanent
            }
            try playlistTable.update(db, playlist)
            return true
        }
    }
}
