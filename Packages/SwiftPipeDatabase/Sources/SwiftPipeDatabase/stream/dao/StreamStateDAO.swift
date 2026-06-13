// Mirrors: app/src/main/java/org/schabi/newpipe/database/stream/dao/StreamStateDAO.kt @ v0.27.x

import GRDB

public struct StreamStateDAO {
    let dbWriter: DatabaseWriter

    public init(_ dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    // MARK: Queries

    public func getState(_ db: Database, streamId: Int64) throws -> StreamStateEntity? {
        try StreamStateEntity.fetchOne(
            db, sql: "SELECT * FROM stream_state WHERE stream_id = ?", arguments: [streamId])
    }

    @discardableResult
    public func deleteState(_ db: Database, streamId: Int64) throws -> Int {
        try db.execute(sql: "DELETE FROM stream_state WHERE stream_id = ?", arguments: [streamId])
        return db.changesCount
    }

    /// Insert-or-replace the resume position. Mirror of StreamStateDAO.upsert.
    public func upsert(_ db: Database, _ state: StreamStateEntity) throws {
        var state = state
        try state.insert(db, onConflict: .replace)
    }

    // MARK: Convenience wrappers

    public func getState(streamId: Int64) throws -> StreamStateEntity? {
        try dbWriter.read { db in try getState(db, streamId: streamId) }
    }

    public func upsert(_ state: StreamStateEntity) throws {
        try dbWriter.write { db in try upsert(db, state) }
    }

    @discardableResult
    public func deleteState(streamId: Int64) throws -> Int {
        try dbWriter.write { db in try deleteState(db, streamId: streamId) }
    }
}
