// Mirrors: app/src/main/java/org/schabi/newpipe/database/history/dao/SearchHistoryDAO.kt @ v0.27.x

import GRDB

public struct SearchHistoryDAO {
    let dbWriter: DatabaseWriter

    public init(_ dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    // MARK: Queries

    public func latestEntry(_ db: Database) throws -> SearchHistoryEntry? {
        try SearchHistoryEntry.fetchOne(db, sql: """
            SELECT * FROM search_history WHERE id = (SELECT MAX(id) FROM search_history)
            """)
    }

    public func getAll(_ db: Database) throws -> [SearchHistoryEntry] {
        try SearchHistoryEntry.fetchAll(
            db, sql: "SELECT * FROM search_history ORDER BY creation_date DESC")
    }

    /// Distinct search terms, most-recently-used first. Mirror of getUniqueEntries.
    public func getUniqueEntries(_ db: Database, limit: Int) throws -> [String] {
        try String.fetchAll(db, sql: """
            SELECT search FROM search_history GROUP BY search ORDER BY MAX(creation_date) DESC LIMIT ?
            """, arguments: [limit])
    }

    /// Autocomplete: distinct terms starting with `query`. Mirror of getSimilarEntries.
    public func getSimilarEntries(_ db: Database, query: String, limit: Int) throws -> [String] {
        try String.fetchAll(db, sql: """
            SELECT search FROM search_history WHERE search LIKE ? || '%'
            GROUP BY search ORDER BY MAX(creation_date) DESC LIMIT ?
            """, arguments: [query, limit])
    }

    @discardableResult
    public func deleteAll(_ db: Database) throws -> Int {
        try db.execute(sql: "DELETE FROM search_history")
        return db.changesCount
    }

    @discardableResult
    public func deleteAllWhereQuery(_ db: Database, query: String) throws -> Int {
        try db.execute(sql: "DELETE FROM search_history WHERE search = ?", arguments: [query])
        return db.changesCount
    }

    @discardableResult
    public func insert(_ db: Database, _ entry: SearchHistoryEntry) throws -> Int64 {
        var entry = entry
        try entry.insert(db)
        return entry.id
    }

    // MARK: Convenience wrappers

    public func latestEntry() throws -> SearchHistoryEntry? {
        try dbWriter.read { db in try latestEntry(db) }
    }

    public func getAll() throws -> [SearchHistoryEntry] {
        try dbWriter.read { db in try getAll(db) }
    }

    public func getUniqueEntries(limit: Int) throws -> [String] {
        try dbWriter.read { db in try getUniqueEntries(db, limit: limit) }
    }

    public func getSimilarEntries(query: String, limit: Int) throws -> [String] {
        try dbWriter.read { db in try getSimilarEntries(db, query: query, limit: limit) }
    }

    @discardableResult
    public func insert(_ entry: SearchHistoryEntry) throws -> Int64 {
        try dbWriter.write { db in try insert(db, entry) }
    }

    @discardableResult
    public func deleteAll() throws -> Int {
        try dbWriter.write { db in try deleteAll(db) }
    }

    @discardableResult
    public func deleteAllWhereQuery(_ query: String) throws -> Int {
        try dbWriter.write { db in try deleteAllWhereQuery(db, query: query) }
    }
}
