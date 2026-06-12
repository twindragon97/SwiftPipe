// SwiftPipeDatabase — byte-compatible mirror of NewPipe Android's newpipe.db.
//
// Hard requirements (see the implementation plan and docs/PORTING.md):
//  - Schema DDL is executed as literal SQL mirrored from the Android app's
//    database/Migrations.kt (NOT GRDB's migrator DSL), so sqlite_master stays
//    identical to what Room emits, including index names.
//  - `PRAGMA user_version` = 9 and the `room_master_table.identity_hash` row
//    must be present on export, or Android NewPipe rejects the database.
//  - Import replaces the database file (mirror of ImportExportManager.extractDb):
//    close pool → delete db + journal/shm/wal → extract → integrity_check →
//    run mirrored migrations up to v9 → reopen.
//
// The real schema lands in Phase 4.

public enum SwiftPipeDatabase {
    /// Room schema version of NewPipe Android that this package mirrors.
    public static let schemaVersion = 9

    /// Database file name — deliberately identical to Android NewPipe.
    public static let databaseFileName = "newpipe.db"

    /// Placeholder used by the Phase 0 bootstrap tests.
    public static let bootstrap = true
}
