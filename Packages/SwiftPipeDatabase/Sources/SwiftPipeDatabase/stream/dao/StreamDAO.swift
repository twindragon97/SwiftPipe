// Mirrors: app/src/main/java/org/schabi/newpipe/database/stream/dao/StreamDAO.kt @ v0.27.x
//
// Room's DAOs return RxJava Flowables; here the equivalent queries are plain
// throwing methods over a GRDB connection (the app layer wraps lists in
// ValueObservation for reactive UI). The faithful part is the SQL and the
// upsert/compare logic, which keeps a stream row deduplicated by (service_id,
// url) exactly as Android does.

import Foundation
import GRDB
import SwiftPipeExtractor

public struct StreamDAO {
    let dbWriter: DatabaseWriter

    public init(_ dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    // MARK: Queries (operate on a provided connection)

    public func getStream(_ db: Database, serviceId: Int, url: String) throws -> StreamEntity? {
        try StreamEntity.fetchOne(
            db,
            sql: "SELECT * FROM streams WHERE url = ? AND service_id = ?",
            arguments: [url, serviceId])
    }

    /// Inserts the stream if new, otherwise reconciles it with the existing row
    /// and returns its uid. Mirror of StreamDAO.upsert + compareAndUpdateStream.
    @discardableResult
    public func upsert(_ db: Database, _ stream: inout StreamEntity) throws -> Int64 {
        try stream.insert(db, onConflict: .ignore)
        if db.changesCount > 0 {
            // A new row was inserted; didInsert assigned stream.uid.
            return stream.uid
        }

        // The row already existed (insert ignored). Reconcile and update.
        guard let existing = try getStream(db, serviceId: stream.serviceId, url: stream.url) else {
            // Should be impossible right after a conflict.
            return stream.uid
        }
        stream.uid = existing.uid

        if !Self.isLiveStream(stream.streamType) {
            // Keep the existing upload date unless the newer one is more precise
            // (i.e. not an approximation), to avoid pointless churn.
            let hasBetterPrecision =
                stream.uploadDate != nil && stream.isUploadDateApproximation != true
            if existing.uploadDate != nil && !hasBetterPrecision {
                stream.uploadDate = existing.uploadDate
                stream.textualUploadDate = existing.textualUploadDate
                stream.isUploadDateApproximation = existing.isUploadDateApproximation
            }
            if existing.duration > 0 && stream.duration < 0 {
                stream.duration = existing.duration
            }
        }

        try stream.update(db)
        return stream.uid
    }

    /// Upserts each stream, returning their uids in order. Mirror of upsertAll.
    @discardableResult
    public func upsertAll(_ db: Database, _ streams: [StreamEntity]) throws -> [Int64] {
        var ids: [Int64] = []
        ids.reserveCapacity(streams.count)
        for stream in streams {
            var stream = stream
            ids.append(try upsert(db, &stream))
        }
        return ids
    }

    /// Deletes streams not referenced by history, a playlist or the feed.
    /// Mirror of StreamDAO.deleteOrphans.
    @discardableResult
    public func deleteOrphans(_ db: Database) throws -> Int {
        try db.execute(sql: """
            DELETE FROM streams WHERE
            NOT EXISTS (SELECT 1 FROM stream_history sh WHERE sh.stream_id = streams.uid)
            AND NOT EXISTS (SELECT 1 FROM playlist_stream_join ps WHERE ps.stream_id = streams.uid)
            AND NOT EXISTS (SELECT 1 FROM feed f WHERE f.stream_id = streams.uid)
            """)
        return db.changesCount
    }

    // MARK: Convenience wrappers (manage their own transaction)

    @discardableResult
    public func upsert(_ stream: inout StreamEntity) throws -> Int64 {
        var copy = stream
        let uid = try dbWriter.write { db in try upsert(db, &copy) }
        stream = copy
        return uid
    }

    /// Mirror of StreamTypeUtil.isLiveStream: ongoing live broadcasts only
    /// (post-live VODs are treated as normal streams again).
    static func isLiveStream(_ type: StreamType) -> Bool {
        type == .LIVE_STREAM || type == .AUDIO_LIVE_STREAM
    }
}
