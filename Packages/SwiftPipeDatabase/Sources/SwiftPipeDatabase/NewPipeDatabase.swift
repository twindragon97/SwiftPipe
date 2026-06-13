// The database holder, analogous to Android's AppDatabase singleton: it owns the
// GRDB connection to newpipe.db, creates the v9 schema on a fresh file, and
// vends DAOs. Foreign-key enforcement is on (GRDB default) so the CASCADE rules
// mirrored from Room behave identically.

import Foundation
import GRDB

public final class NewPipeDatabase {
    public let dbWriter: DatabaseWriter

    /// Opens (creating if missing) newpipe.db at `path` and ensures the schema.
    public init(path: String) throws {
        let queue = try DatabaseQueue(path: path, configuration: Self.configuration)
        self.dbWriter = queue
        try setUpSchemaIfNeeded()
    }

    /// In-memory database — used by tests and previews.
    public static func inMemory() throws -> NewPipeDatabase {
        try NewPipeDatabase(dbWriter: DatabaseQueue(configuration: configuration))
    }

    private init(dbWriter: DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try setUpSchemaIfNeeded()
    }

    private static var configuration: Configuration {
        var config = Configuration()
        config.foreignKeysEnabled = true
        return config
    }

    /// Creates the v9 schema on an empty database. A non-empty database with a
    /// different `user_version` is left untouched here — migrating an imported
    /// older database is handled by the import path (mirror of
    /// ImportExportManager), not on every open.
    private func setUpSchemaIfNeeded() throws {
        try dbWriter.write { db in
            let userVersion = try Int.fetchOne(db, sql: "PRAGMA user_version") ?? 0
            let hasTables = try Bool.fetchOne(
                db,
                sql: "SELECT COUNT(*) > 0 FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'"
            ) ?? false
            if userVersion == 0 && !hasTables {
                try AppDatabase.createSchema(db)
            }
        }
    }
}
