import XCTest
import GRDB
@testable import SwiftPipeDatabase

final class BootstrapTests: XCTestCase {
    /// Smoke-checks that GRDB links and can drive the PRAGMAs the Android
    /// compatibility layer depends on (user_version is how Room/SQLiteOpenHelper
    /// track the schema version).
    func testGRDBHandlesUserVersionPragma() throws {
        let dbQueue = try DatabaseQueue()
        try dbQueue.write { db in
            try db.execute(sql: "PRAGMA user_version = \(SwiftPipeDatabase.schemaVersion)")
        }
        let version = try dbQueue.read { db in
            try Int.fetchOne(db, sql: "PRAGMA user_version")
        }
        XCTAssertEqual(version, SwiftPipeDatabase.schemaVersion)
    }
}
