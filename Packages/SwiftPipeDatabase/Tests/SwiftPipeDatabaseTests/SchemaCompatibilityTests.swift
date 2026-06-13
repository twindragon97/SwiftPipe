import XCTest
import GRDB
@testable import SwiftPipeDatabase

/// Proves the database SwiftPipe builds is byte-compatible with the schema Room
/// generates for NewPipe Android v9. Ground truth is the verbatim copy of
/// upstream's `9.json` (the Room schema export) bundled as a test resource — so
/// any transcription error in AppDatabase.createStatements fails this test
/// rather than silently producing a database Android rejects.
final class SchemaCompatibilityTests: XCTestCase {

    // MARK: 9.json model (only the fields we assert on)

    private struct RoomSchema: Decodable {
        struct Database: Decodable {
            let version: Int
            let identityHash: String
            let entities: [Entity]
            let setupQueries: [String]
        }
        let database: Database
    }

    private struct Entity: Decodable {
        let tableName: String
        let createSql: String
        let indices: [Index]
    }

    private struct Index: Decodable {
        let name: String
        let createSql: String
    }

    private func loadRoomSchema() throws -> RoomSchema.Database {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "room-schema-9", withExtension: "json"),
            "room-schema-9.json missing from test bundle")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(RoomSchema.self, from: data).database
    }

    /// Room emits `${TABLE_NAME}` placeholders; it substitutes the actual table
    /// name before executing, which is exactly what ends up in sqlite_master.
    private func resolved(_ createSql: String, table: String) -> String {
        createSql.replacingOccurrences(of: "${TABLE_NAME}", with: table)
    }

    // MARK: Tests

    func testEveryTableMatchesRoomDDLByteForByte() throws {
        let schema = try loadRoomSchema()
        let db = try NewPipeDatabase.inMemory()

        let masterByName: [String: String] = try db.dbWriter.read { db in
            try Row.fetchAll(db, sql: "SELECT name, sql FROM sqlite_master WHERE type = 'table'")
                .reduce(into: [:]) { acc, row in acc[row["name"]] = row["sql"] }
        }

        for entity in schema.database.entities {
            let expected = resolved(entity.createSql, table: entity.tableName)
            let actual = try XCTUnwrap(
                masterByName[entity.tableName],
                "table \(entity.tableName) is missing from the database we built")
            XCTAssertEqual(
                actual, expected,
                "DDL for table \(entity.tableName) does not match Room's createSql")
        }
    }

    func testEveryIndexMatchesRoomDDLByteForByte() throws {
        let schema = try loadRoomSchema()
        let db = try NewPipeDatabase.inMemory()

        let masterByName: [String: String] = try db.dbWriter.read { db in
            try Row.fetchAll(db, sql: "SELECT name, sql FROM sqlite_master WHERE type = 'index' AND sql IS NOT NULL")
                .reduce(into: [:]) { acc, row in acc[row["name"]] = row["sql"] }
        }

        for entity in schema.database.entities {
            for index in entity.indices {
                let expected = resolved(index.createSql, table: entity.tableName)
                let actual = try XCTUnwrap(
                    masterByName[index.name],
                    "index \(index.name) is missing from the database we built")
                XCTAssertEqual(
                    actual, expected,
                    "DDL for index \(index.name) does not match Room's createSql")
            }
        }
    }

    func testIdentityHashMatchesRoom() throws {
        let schema = try loadRoomSchema()
        let db = try NewPipeDatabase.inMemory()

        let storedHash = try db.dbWriter.read { db in
            try String.fetchOne(
                db, sql: "SELECT identity_hash FROM room_master_table WHERE id = 42")
        }
        XCTAssertEqual(storedHash, schema.database.identityHash)
        XCTAssertEqual(AppDatabase.identityHash, schema.database.identityHash)
    }

    func testUserVersionIsNine() throws {
        let schema = try loadRoomSchema()
        let db = try NewPipeDatabase.inMemory()

        let userVersion = try db.dbWriter.read { db in
            try Int.fetchOne(db, sql: "PRAGMA user_version")
        }
        XCTAssertEqual(userVersion, schema.database.version)
        XCTAssertEqual(userVersion, 9)
    }

    /// All 12 NewPipe tables exist (plus room_master_table, plus the
    /// autoincrement bookkeeping table sqlite creates for AUTOINCREMENT).
    func testAllTwelveTablesExist() throws {
        let db = try NewPipeDatabase.inMemory()
        let tables: Set<String> = try db.dbWriter.read { db in
            Set(try String.fetchAll(
                db,
                sql: "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'"))
        }
        let expected: Set<String> = [
            "subscriptions", "search_history", "streams", "stream_history",
            "stream_state", "playlists", "playlist_stream_join", "remote_playlists",
            "feed", "feed_group", "feed_group_subscription_join", "feed_last_updated",
            "room_master_table",
        ]
        XCTAssertEqual(tables, expected)
    }
}
