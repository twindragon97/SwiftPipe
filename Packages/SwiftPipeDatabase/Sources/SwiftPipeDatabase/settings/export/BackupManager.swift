// Mirrors: app/src/main/java/org/schabi/newpipe/settings/export/ImportExportManager.kt
// (+ BackupFileLocator.kt) @ v0.27.x
//
// Reads and writes the NewPipeData backup .zip so subscriptions, history,
// playlists and resume positions can move between SwiftPipe and NewPipe Android.
// The archive contains the database (`newpipe.db`) and JSON preferences
// (`preferences.json`). We deliberately do NOT emit the legacy
// `newpipe.settings` (Java-serialised, deprecated and insecure upstream);
// current NewPipe restores from preferences.json when present. Documented
// limitation: a pre-preferences.json NewPipe cannot restore our export.

import Foundation
import GRDB
import ZIPFoundation

public enum BackupManager {
    /// Entry names inside the zip (mirror of BackupFileLocator constants).
    static let fileNameDb = "newpipe.db"
    static let fileNameJsonPrefs = "preferences.json"

    public struct ImportResult: Equatable {
        public let userVersion: Int
        public let identityHash: String?
        /// Raw preferences.json bytes, kept so a later export can round-trip the
        /// original Android settings unchanged.
        public let preferencesJSON: Data?

        /// True when the imported schema matches the v9 SwiftPipe mirrors.
        public var isSchemaV9: Bool { identityHash == AppDatabase.identityHash }
    }

    public enum BackupError: Error, CustomStringConvertible {
        case databaseEntryMissing
        case integrityCheckFailed(String)
        case notANewPipeDatabase

        public var description: String {
            switch self {
            case .databaseEntryMissing:
                return "The backup does not contain a \(fileNameDb) entry."
            case .integrityCheckFailed(let detail):
                return "The database failed its integrity check: \(detail)."
            case .notANewPipeDatabase:
                return "The file is not a NewPipe database backup."
            }
        }
    }

    // MARK: Export

    /// Writes a NewPipeData-style zip (newpipe.db + preferences.json) at
    /// `outputURL`, overwriting it if present. The database is copied with
    /// `VACUUM INTO`, producing a single, consistent, WAL-free file.
    public static func exportDatabase(
        from database: NewPipeDatabase,
        preferencesJSON: Data? = nil,
        to outputURL: URL
    ) throws {
        let fm = FileManager.default
        let work = fm.temporaryDirectory
            .appendingPathComponent("spexport-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: work, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: work) }

        let dbCopy = work.appendingPathComponent(fileNameDb)
        let escaped = dbCopy.path.replacingOccurrences(of: "'", with: "''")
        // VACUUM cannot run inside a transaction.
        try database.dbWriter.writeWithoutTransaction { db in
            try db.execute(sql: "VACUUM INTO '\(escaped)'")
        }

        // Always include preferences.json so modern NewPipe restores prefs.
        let prefs = work.appendingPathComponent(fileNameJsonPrefs)
        try (preferencesJSON ?? Data("{}".utf8)).write(to: prefs)

        if fm.fileExists(atPath: outputURL.path) {
            try fm.removeItem(at: outputURL)
        }
        try fm.zipItem(at: work, to: outputURL, shouldKeepParent: false)
    }

    // MARK: Import

    /// Replaces the database at `dbPath` with the `newpipe.db` inside `zipURL`,
    /// after validating it. Any open connection to `dbPath` MUST be closed by the
    /// caller first. Returns the schema metadata and the preferences.json bytes.
    @discardableResult
    public static func importDatabase(from zipURL: URL, toDatabaseAt dbPath: URL) throws -> ImportResult {
        let fm = FileManager.default
        let work = fm.temporaryDirectory
            .appendingPathComponent("spimport-\(UUID().uuidString)", isDirectory: true)
        defer { try? fm.removeItem(at: work) }
        try fm.unzipItem(at: zipURL, to: work)

        let extractedDb = work.appendingPathComponent(fileNameDb)
        guard fm.fileExists(atPath: extractedDb.path) else {
            throw BackupError.databaseEntryMissing
        }

        let (userVersion, identityHash) = try validate(extractedDb)

        let prefsURL = work.appendingPathComponent(fileNameJsonPrefs)
        let prefsData = try? Data(contentsOf: prefsURL)

        // Replace the live database file and any stale sidecars.
        for suffix in ["", "-journal", "-wal", "-shm"] {
            try? fm.removeItem(at: URL(fileURLWithPath: dbPath.path + suffix))
        }
        try fm.createDirectory(
            at: dbPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fm.moveItem(at: extractedDb, to: dbPath)

        return ImportResult(
            userVersion: userVersion, identityHash: identityHash, preferencesJSON: prefsData)
    }

    /// Opens the extracted database read-only-style and checks it is a sound
    /// NewPipe database before we overwrite the user's data with it. The
    /// connection is closed before the caller moves the file.
    private static func validate(_ dbURL: URL) throws -> (Int, String?) {
        let queue = try DatabaseQueue(path: dbURL.path)
        return try queue.read { db in
            let integrity = try String.fetchOne(db, sql: "PRAGMA integrity_check") ?? "?"
            guard integrity == "ok" else {
                throw BackupError.integrityCheckFailed(integrity)
            }
            let hasCore = try Bool.fetchOne(
                db,
                sql: "SELECT COUNT(*) > 0 FROM sqlite_master WHERE type = 'table' AND name = 'subscriptions'"
            ) ?? false
            guard hasCore else { throw BackupError.notANewPipeDatabase }

            let userVersion = try Int.fetchOne(db, sql: "PRAGMA user_version") ?? 0
            let identity = try String.fetchOne(
                db, sql: "SELECT identity_hash FROM room_master_table WHERE id = 42")
            return (userVersion, identity)
        }
    }
}
