// Mirrors: app/src/main/java/org/schabi/newpipe/database/history/dao/StreamHistoryDAO.kt @ v0.27.x

import Foundation
import GRDB

public struct StreamHistoryDAO {
    let dbWriter: DatabaseWriter

    public init(_ dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    // MARK: Queries

    /// Watch history newest-first, joined with the stream rows.
    public func history(_ db: Database) throws -> [StreamHistoryEntry] {
        try StreamHistoryEntry.fetchAll(db, sql: """
            SELECT * FROM streams INNER JOIN stream_history ON uid = stream_id
            ORDER BY access_date DESC
            """)
    }

    /// Most-watched / statistics view: latest access and total watch count per
    /// stream, with the resume position. Mirror of getStatistics().
    public func statistics(_ db: Database) throws -> [StreamStatisticsEntry] {
        try StreamStatisticsEntry.fetchAll(db, sql: """
            SELECT * FROM streams
            INNER JOIN (
                SELECT stream_id, MAX(access_date) AS latestAccess, SUM(repeat_count) AS watchCount
                FROM stream_history
                GROUP BY stream_id
            )
            ON uid = stream_id
            LEFT JOIN (SELECT stream_id AS stream_id_alias, progress_time FROM stream_state)
            ON uid = stream_id_alias
            """)
    }

    public func getLatestEntry(_ db: Database, streamId: Int64) throws -> StreamHistoryEntity? {
        try StreamHistoryEntity.fetchOne(db, sql: """
            SELECT * FROM stream_history WHERE stream_id = ? ORDER BY access_date DESC LIMIT 1
            """, arguments: [streamId])
    }

    @discardableResult
    public func deleteStreamHistory(_ db: Database, streamId: Int64) throws -> Int {
        try db.execute(sql: "DELETE FROM stream_history WHERE stream_id = ?", arguments: [streamId])
        return db.changesCount
    }

    @discardableResult
    public func deleteAll(_ db: Database) throws -> Int {
        try db.execute(sql: "DELETE FROM stream_history")
        return db.changesCount
    }

    public func insert(_ db: Database, _ entity: StreamHistoryEntity) throws {
        var entity = entity
        try entity.insert(db)
    }

    public func update(_ db: Database, _ entity: StreamHistoryEntity) throws {
        try entity.update(db)
    }

    // MARK: Convenience wrappers

    public func history() throws -> [StreamHistoryEntry] {
        try dbWriter.read { db in try history(db) }
    }

    public func statistics() throws -> [StreamStatisticsEntry] {
        try dbWriter.read { db in try statistics(db) }
    }

    public func getLatestEntry(streamId: Int64) throws -> StreamHistoryEntity? {
        try dbWriter.read { db in try getLatestEntry(db, streamId: streamId) }
    }

    @discardableResult
    public func deleteStreamHistory(streamId: Int64) throws -> Int {
        try dbWriter.write { db in try deleteStreamHistory(db, streamId: streamId) }
    }

    @discardableResult
    public func deleteAll() throws -> Int {
        try dbWriter.write { db in try deleteAll(db) }
    }
}
