import XCTest
import GRDB
@testable import SwiftPipeDatabase

/// Verifies the NewPipeData backup round-trips: export → import reproduces the
/// data, preserves the Room identity hash / user_version (so Android accepts it),
/// carries preferences.json through, and replaces an existing database.
final class BackupManagerTests: XCTestCase {

    private var workDir: URL!

    override func setUpWithError() throws {
        workDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("spbackuptest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: workDir)
    }

    private func makeZip(subscription name: String, prefs: Data?) throws -> URL {
        let dbPath = workDir.appendingPathComponent("source-\(UUID().uuidString).db")
        let zipURL = workDir.appendingPathComponent("backup-\(UUID().uuidString).zip")
        // Scope the source database so its connection is closed before we zip.
        let db = try NewPipeDatabase(path: dbPath.path)
        _ = try db.subscriptionDAO.insert(
            SubscriptionEntity(serviceId: 0, url: "https://yt/\(name)", name: name))
        try BackupManager.exportDatabase(from: db, preferencesJSON: prefs, to: zipURL)
        return zipURL
    }

    func testExportImportRoundTrip() throws {
        let prefs = Data(#"{"enable_watch_history":true}"#.utf8)
        let zipURL = try makeZip(subscription: "Chan", prefs: prefs)
        XCTAssertTrue(FileManager.default.fileExists(atPath: zipURL.path))

        let target = workDir.appendingPathComponent("restored.db")
        let result = try BackupManager.importDatabase(from: zipURL, toDatabaseAt: target)

        XCTAssertEqual(result.userVersion, 9)
        XCTAssertEqual(result.identityHash, AppDatabase.identityHash)
        XCTAssertTrue(result.isSchemaV9)
        XCTAssertEqual(result.preferencesJSON, prefs)

        let restored = try NewPipeDatabase(path: target.path)
        XCTAssertEqual(try restored.subscriptionDAO.getAll().map(\.name), ["Chan"])
    }

    func testImportReplacesExistingDatabase() throws {
        let zipURL = try makeZip(subscription: "Imported", prefs: nil)

        let target = workDir.appendingPathComponent("existing.db")
        // Pre-existing database with different data; close it before importing.
        do {
            let existing = try NewPipeDatabase(path: target.path)
            _ = try existing.subscriptionDAO.insert(
                SubscriptionEntity(serviceId: 0, url: "https://yt/old", name: "Old"))
        }

        _ = try BackupManager.importDatabase(from: zipURL, toDatabaseAt: target)

        let restored = try NewPipeDatabase(path: target.path)
        XCTAssertEqual(
            try restored.subscriptionDAO.getAll().map(\.name), ["Imported"],
            "import must replace, not merge")
    }

    func testImportRejectsNonNewPipeZip() throws {
        // A zip that contains a file named newpipe.db but isn't a NewPipe database.
        let staging = workDir.appendingPathComponent("junk", isDirectory: true)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        try Data("not a database".utf8)
            .write(to: staging.appendingPathComponent("newpipe.db"))
        let zipURL = workDir.appendingPathComponent("junk.zip")
        try FileManager.default.zipItem(at: staging, to: zipURL, shouldKeepParent: false)

        let target = workDir.appendingPathComponent("untouched.db")
        XCTAssertThrowsError(try BackupManager.importDatabase(from: zipURL, toDatabaseAt: target))
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: target.path),
            "a rejected import must not create/replace the target database")
    }
}
